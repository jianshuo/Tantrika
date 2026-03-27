# Tantrika — Xcode Setup Checklist

Complete these steps before the project will build. Code is ready; these are
the Xcode/third-party integrations that can't be automated from the command line.

## 1. Add SPM packages

In Xcode → File → Add Package Dependencies:

```
https://github.com/supabase/supabase-swift   (branch: main)
https://github.com/RevenueCat/purchases-ios   (branch: main)
```

Add to the **Tantrika** app target:
- `Supabase` (from supabase-swift)
- `RevenueCat` (from purchases-ios)

## 2. Bundle Cormorant Garant fonts

1. Download the free OTF files from https://fonts.google.com/specimen/Cormorant+Garant
   - CormorantGarant-Light.otf
   - CormorantGarant-Regular.otf
   - CormorantGarant-LightItalic.otf
2. Drag into Xcode → Tantrika group → check "Add to target: Tantrika"
3. In Info.plist add key `Fonts provided by application` (UIAppFonts) with the three filenames as items.

## 3. Info.plist keys

Add these keys (use $(VAR) or xcconfig for secrets — never hardcode):

| Key | Value |
|-----|-------|
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | Your Supabase anon key |
| `REVENUECAT_API_KEY` | Your RevenueCat iOS API key |

## 4. Supabase project setup

### Database tables

```sql
-- profiles (created automatically on auth.users insert via trigger)
create table profiles (
  id uuid references auth.users primary key,
  is_subscribed boolean not null default false,
  created_at timestamptz not null default now()
);

create table courses (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null default '',
  thumbnail_url text,
  lesson_count int not null default 0,
  total_duration_seconds int not null default 0,
  sort_order int not null default 0
);

create table lessons (
  id uuid primary key default gen_random_uuid(),
  course_id uuid references courses not null,
  title text not null,
  description text,
  duration_seconds int not null default 0,
  sort_order int not null default 0,
  is_free_preview boolean not null default false,
  cf_video_id text not null,
  thumbnail_url text
);

create table user_progress (
  user_id uuid references auth.users not null,
  lesson_id uuid references lessons not null,
  watched_seconds int not null default 0,
  is_completed boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (user_id, lesson_id)
);
```

### Row Level Security

```sql
-- profiles: users read/update their own row
alter table profiles enable row level security;
create policy "own profile" on profiles
  for all using (auth.uid() = id);

-- courses: anyone authenticated can read
alter table courses enable row level security;
create policy "read courses" on courses
  for select using (auth.role() = 'authenticated');

-- lessons: anyone authenticated can read
alter table lessons enable row level security;
create policy "read lessons" on lessons
  for select using (auth.role() = 'authenticated');

-- user_progress: users read/write their own rows
alter table user_progress enable row level security;
create policy "own progress" on user_progress
  for all using (auth.uid() = user_id);
```

### Auto-create profile on signup

```sql
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id) values (new.id);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
```

### Deploy Edge Function

```bash
supabase functions deploy sign-video-url
supabase secrets set \
  CF_ACCOUNT_ID=<your-cf-account-id> \
  CF_STREAM_SIGNING_KEY_ID=<your-key-id> \
  CF_STREAM_SIGNING_SECRET="$(cat your-private-key.pem)"
```

## 5. RevenueCat setup

1. Create a "pro" entitlement in the RevenueCat dashboard
2. Add monthly and annual products in App Store Connect
3. Link them to a RevenueCat Offering named "default"

## 6. Sign in with Apple

In Xcode → Signing & Capabilities → + Capability → Sign in with Apple

In Supabase → Authentication → Providers → Apple:
- Add your App ID and a generated client secret

---

That's it. Once these are done, the app will build and run end-to-end.
