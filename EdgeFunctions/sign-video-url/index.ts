import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Environment variables (set in Supabase dashboard — never hardcoded)
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const CF_ACCOUNT_ID = Deno.env.get("CF_ACCOUNT_ID")!;
const CF_STREAM_SIGNING_KEY_ID = Deno.env.get("CF_STREAM_SIGNING_KEY_ID")!;
const CF_STREAM_SIGNING_SECRET = Deno.env.get("CF_STREAM_SIGNING_SECRET")!;

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

    // 5. Sign Cloudflare Stream URL (1h TTL)
    const signedUrl = await signCloudflareStreamUrl(lesson.cf_video_id, 3600);

    return new Response(JSON.stringify({ url: signedUrl }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (err) {
    console.error("sign-video-url error:", err);
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

// ---------------------------------------------------------------------------
// Cloudflare Stream signed URL via RSA-PSS JWT
// Docs: https://developers.cloudflare.com/stream/viewing-videos/securing-your-stream/
// ---------------------------------------------------------------------------

async function signCloudflareStreamUrl(videoId: string, ttlSeconds: number): Promise<string> {
  const expiresAt = Math.floor(Date.now() / 1000) + ttlSeconds;

  const header = { alg: "RS256", kid: CF_STREAM_SIGNING_KEY_ID };
  const payload = {
    sub: videoId,
    kid: CF_STREAM_SIGNING_KEY_ID,
    exp: expiresAt,
    accessRules: [{ type: "any", action: "allow" }],
  };

  const encodedHeader  = btoa(JSON.stringify(header)).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
  const encodedPayload = btoa(JSON.stringify(payload)).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
  const signingInput   = `${encodedHeader}.${encodedPayload}`;

  // Import PEM key
  const pem = CF_STREAM_SIGNING_SECRET
    .replace(/-----BEGIN RSA PRIVATE KEY-----/, "")
    .replace(/-----END RSA PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");
  const keyData = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    keyData,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(signingInput)
  );

  const encodedSignature = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");

  const token = `${signingInput}.${encodedSignature}`;
  return `https://customer-${CF_ACCOUNT_ID}.cloudflarestream.com/${token}/manifest/video.m3u8`;
}
