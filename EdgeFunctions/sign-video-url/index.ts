import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Environment variables — only Supabase credentials needed (no CF signing keys)
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
// Cloudflare Stream subdomain (no signing — videos must be set to public in CF dashboard)
const CF_CUSTOMER_SUBDOMAIN = Deno.env.get("CF_CUSTOMER_SUBDOMAIN") ?? "customer-h0sfnfbe1tutii84.cloudflarestream.com";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // 1. Parse request
    const { lessonId } = await req.json() as { lessonId: string };
    if (!lessonId) {
      return new Response(JSON.stringify({ error: "lessonId is required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 2. Verify caller JWT
    const authHeader = req.headers.get("authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);

    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 3. Fetch lesson
    const { data: lesson, error: lessonError } = await supabase
      .from("lessons")
      .select("cf_video_id, is_free_preview")
      .eq("id", lessonId)
      .single();

    if (lessonError || !lesson) {
      return new Response(JSON.stringify({ error: "Lesson not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 4. Check access — free preview passes, paid requires subscription
    if (!lesson.is_free_preview) {
      const { data: profile, error: profileError } = await supabase
        .from("profiles")
        .select("is_subscribed")
        .eq("id", user.id)
        .single();

      if (profileError || !profile?.is_subscribed) {
        return new Response(JSON.stringify({ error: "Forbidden" }), {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
    }

    // 5. Build video URL (unsigned — videos must be public in Cloudflare Stream dashboard)
    // If cf_video_id is already a full URL (demo/testing), return it directly.
    // Otherwise build the standard Cloudflare Stream HLS manifest URL.
    const videoUrl = lesson.cf_video_id.startsWith("https://")
      ? lesson.cf_video_id
      : `https://${CF_CUSTOMER_SUBDOMAIN}/${lesson.cf_video_id}/manifest/video.m3u8`;

    return new Response(JSON.stringify({ url: videoUrl }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (err) {
    console.error("get-video-url error:", err);
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
