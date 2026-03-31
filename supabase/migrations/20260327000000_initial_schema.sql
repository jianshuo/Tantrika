-- Tantrika v1 — Initial Schema
-- Run via: supabase db push
-- Or manually in Supabase Dashboard → SQL Editor

-- ─────────────────────────────────────────────
-- profiles
-- Created automatically via trigger on auth.users insert
-- ─────────────────────────────────────────────
create table if not exists profiles (
  id            uuid references auth.users primary key,
  is_subscribed boolean not null default false,
  created_at    timestamptz not null default now()
);

alter table profiles enable row level security;

drop policy if exists "own profile" on profiles;
create policy "own profile" on profiles
  for all using (auth.uid() = id);

-- ─────────────────────────────────────────────
-- courses
-- ─────────────────────────────────────────────
create table if not exists courses (
  id                     uuid primary key default gen_random_uuid(),
  title                  text not null,
  description            text not null default '',
  thumbnail_url          text,
  lesson_count           int  not null default 0,
  total_duration_seconds int  not null default 0,
  sort_order             int  not null default 0
);

alter table courses enable row level security;

drop policy if exists "read courses" on courses;
create policy "read courses" on courses
  for select using (auth.role() = 'authenticated');

-- ─────────────────────────────────────────────
-- lessons
-- ─────────────────────────────────────────────
create table if not exists lessons (
  id              uuid primary key default gen_random_uuid(),
  course_id       uuid references courses not null,
  title           text not null,
  description     text,
  duration_seconds int not null default 0,
  sort_order      int not null default 0,
  is_free_preview boolean not null default false,
  cf_video_id     text not null,  -- Cloudflare Stream video ID (or full HTTPS URL for demo)
  thumbnail_url   text
);

alter table lessons enable row level security;

drop policy if exists "read lessons" on lessons;
create policy "read lessons" on lessons
  for select using (auth.role() = 'authenticated');

create index if not exists lessons_course_id_idx on lessons(course_id);

-- ─────────────────────────────────────────────
-- user_progress
-- ─────────────────────────────────────────────
create table if not exists user_progress (
  user_id          uuid references auth.users not null,
  lesson_id        uuid references lessons     not null,
  watched_seconds  int not null default 0,
  is_completed     boolean not null default false,
  updated_at       timestamptz not null default now(),
  primary key (user_id, lesson_id)
);

alter table user_progress enable row level security;

drop policy if exists "own progress" on user_progress;
create policy "own progress" on user_progress
  for all using (auth.uid() = user_id);

create index if not exists user_progress_user_id_idx on user_progress(user_id);

-- ─────────────────────────────────────────────
-- Auto-create profile row on new user sign-up
-- ─────────────────────────────────────────────
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id) values (new.id)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
