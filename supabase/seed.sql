-- Tantrika — Seed Data (Demo)
-- Inserts sample course + lessons with a publicly playable HLS stream for demo.
-- The cf_video_id column holds a full HTTPS URL here; the Edge Function detects
-- this and returns it directly without Cloudflare signing (demo mode only).
-- Replace with real Cloudflare Stream video IDs before production.

-- ─────────────────────────────────────────────
-- Course 1: Foundations of Tantric Awareness
-- ─────────────────────────────────────────────
insert into courses (id, title, description, thumbnail_url, lesson_count, total_duration_seconds, sort_order)
values (
  'a1b2c3d4-0000-0000-0000-000000000001',
  'Foundations of Tantric Awareness',
  'Begin here. Astiko introduces the core concepts that underpin all Tantric practice — presence, breath, and the awakened body.',
  null,
  4,
  3120,  -- 52 minutes total
  1
)
on conflict (id) do update set
  title                  = excluded.title,
  description            = excluded.description,
  lesson_count           = excluded.lesson_count,
  total_duration_seconds = excluded.total_duration_seconds;

-- Lessons for course 1
-- cf_video_id = full HTTPS URL → Edge Function demo mode (no CF signing needed)
-- Replace with real Cloudflare Stream video IDs for production.

insert into lessons (id, course_id, title, description, duration_seconds, sort_order, is_free_preview, cf_video_id)
values
  (
    'b1000000-0000-0000-0000-000000000001',
    'a1b2c3d4-0000-0000-0000-000000000001',
    'The Ground of Being',
    'What does it mean to truly arrive? In this opening session, Astiko guides you through a practice of full-body presence.',
    480,  -- 8 min
    1,
    true,  -- free preview
    -- Apple Bitrate-switching HLS test stream (public, no auth needed)
    'https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8'
  ),
  (
    'b1000000-0000-0000-0000-000000000002',
    'a1b2c3d4-0000-0000-0000-000000000001',
    'Breath as the Bridge',
    'The breath is the most direct path between the conscious and unconscious body. Learn the foundational pranayama of Tantric practice.',
    780,  -- 13 min
    2,
    false,
    -- Same demo video; swap for real CF video ID in production
    'https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8'
  ),
  (
    'b1000000-0000-0000-0000-000000000003',
    'a1b2c3d4-0000-0000-0000-000000000001',
    'The Witness and the Felt Sense',
    'Develop the capacity to observe sensation without collapsing into it or pushing it away.',
    900,  -- 15 min
    3,
    false,
    'https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8'
  ),
  (
    'b1000000-0000-0000-0000-000000000004',
    'a1b2c3d4-0000-0000-0000-000000000001',
    'Integration: Closing the Circle',
    'A gentle closing practice. How to carry this quality of awareness off the mat and into daily life.',
    960,  -- 16 min
    4,
    false,
    'https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8'
  )
on conflict (id) do update set
  title            = excluded.title,
  description      = excluded.description,
  duration_seconds = excluded.duration_seconds,
  sort_order       = excluded.sort_order,
  is_free_preview  = excluded.is_free_preview,
  cf_video_id      = excluded.cf_video_id;

-- ─────────────────────────────────────────────
-- Course 2: Breath and Body as Temple
-- ─────────────────────────────────────────────
insert into courses (id, title, description, thumbnail_url, lesson_count, total_duration_seconds, sort_order)
values (
  'a1b2c3d4-0000-0000-0000-000000000002',
  'Breath and Body as Temple',
  'A deeper exploration of embodiment practices. Each lesson builds on the last, moving from individual breath into relational presence.',
  null,
  3,
  2520,  -- 42 minutes total
  2
)
on conflict (id) do update set
  title                  = excluded.title,
  description            = excluded.description,
  lesson_count           = excluded.lesson_count,
  total_duration_seconds = excluded.total_duration_seconds;

insert into lessons (id, course_id, title, description, duration_seconds, sort_order, is_free_preview, cf_video_id)
values
  (
    'b2000000-0000-0000-0000-000000000001',
    'a1b2c3d4-0000-0000-0000-000000000002',
    'The Sacred Container',
    'How do we create the conditions for deep practice? Astiko shares the ritual elements that prepare the body for Tantric work.',
    840,  -- 14 min
    1,
    true,
    'https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8'
  ),
  (
    'b2000000-0000-0000-0000-000000000002',
    'a1b2c3d4-0000-0000-0000-000000000002',
    'Tracking Energy in the Body',
    'Move beyond the conceptual into direct experience. A guided somatic journey through the energy centers.',
    900,  -- 15 min
    2,
    false,
    'https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8'
  ),
  (
    'b2000000-0000-0000-0000-000000000003',
    'a1b2c3d4-0000-0000-0000-000000000002',
    'Relational Presence',
    'Tantric practice is not practiced alone. This session introduces the quality of presence that enables genuine meeting.',
    780,  -- 13 min
    3,
    false,
    'https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8'
  )
on conflict (id) do update set
  title            = excluded.title,
  description      = excluded.description,
  duration_seconds = excluded.duration_seconds,
  sort_order       = excluded.sort_order,
  is_free_preview  = excluded.is_free_preview,
  cf_video_id      = excluded.cf_video_id;
