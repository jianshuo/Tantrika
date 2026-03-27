# Tantrika v1 — Engineering Plan

**Product:** Paid iOS video content platform. Teacher Astiko's Tantra lessons.
**Scope:** Video library browse + playback + auth + subscription gate + progress tracking.
**Target:** iOS 17+, SwiftUI, App Store.

---

## Stack

| Layer | Technology | Why |
|-------|-----------|-----|
| iOS framework | SwiftUI + @Observable | iOS 17+, standard, testable |
| Architecture | MVVM + async/await | Boring by default, protocol-DI friendly |
| Backend/DB | Supabase (PostgreSQL + RLS) | Relational model, Row Level Security for paywall |
| Auth | Supabase Auth + Sign in with Apple | Required for App Store + 3rd-party social |
| Video CDN | Cloudflare Stream | HLS + signed URL, $5/mo + usage |
| Edge compute | Supabase Edge Function (Deno) | Server-side URL signing — secret never in app |
| IAP | RevenueCat + StoreKit 2 | Receipt validation, webhook to Supabase |
| DRM | Skip for v1 (see TODOS.md) | Ships faster; FairPlay added in v1.1 |

---

## Data Model

```
profiles
────────────────────────
id          uuid  PK (FK → auth.users)
is_subscribed  bool  DEFAULT false
created_at  timestamptz

courses
────────────────────────
id           uuid  PK
title        text
description  text
teacher_id   uuid  FK → profiles
thumbnail_url text
sort_order   int

lessons
────────────────────────
id              uuid  PK
title           text
description     text
course_id       uuid  FK → courses
cf_video_id     text  (Cloudflare Stream video ID)
duration_secs   int
sort_order      int
is_free_preview bool  DEFAULT false

user_progress
────────────────────────
user_id         uuid  FK → profiles  }
lesson_id       uuid  FK → lessons   } composite PK
watched_seconds int
completed       bool  DEFAULT false
updated_at      timestamptz
```

**Indexes:**
- `lessons(course_id)` — for library prefetch query
- `user_progress(user_id)` — for progress fetch on library load
- `courses(teacher_id)` — future-proofing for multi-teacher

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        TANTRIKA iOS APP                          │
│                                                                  │
│  ┌──────────┐   ┌──────────────┐   ┌──────────────────────┐    │
│  │ AuthView │   │ LibraryView  │   │    PlayerView         │    │
│  │          │   │ CourseDetail │   │  (AVKit + AVPlayer)   │    │
│  │ Paywall  │   │ View         │   │  PaywallSheet         │    │
│  └────┬─────┘   └──────┬───────┘   └──────────┬───────────┘    │
│       │                │                       │                │
│  ┌────▼─────┐   ┌──────▼───────┐   ┌──────────▼───────────┐    │
│  │ AuthVM   │   │ LibraryVM    │   │  PlayerVM             │    │
│  └────┬─────┘   └──────┬───────┘   └──────────┬───────────┘    │
│       │                │                       │                │
│  ┌────▼──────────────────────────────────────▼──────────────┐  │
│  │                   SupabaseService (protocol)               │  │
│  │          SupabaseEdgeFunctionService (protocol)            │  │
│  │          RevenueCatService (protocol)                      │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────┬──────────────────┬─────────────────┬─────────────────┘
           │                  │                 │
           ▼                  ▼                 ▼
     Supabase Auth      Supabase DB       Cloudflare Stream
     (JWT/Keychain)  (PostgreSQL+RLS)    (HLS signed URLs)
                                               ▲
                                               │ sign-video-url
                                         Supabase Edge Fn
                                               │
                                         CF signing secret
                                         (env var, server-only)
```

---

## Key Flows

### Auth
```
App Launch
    │
    ├── Keychain has Supabase JWT? ──► YES ──► LibraryView
    │
    └── NO ──► AuthView
                │
                └── Sign in with Apple
                        │
                        └── Supabase Auth.signInWithIdToken()
                                │
                                └── JWT → Keychain ──► LibraryView
```

### Video Playback (secure)
```
User taps lesson
    │
    ├── lesson.is_free_preview == true?
    │       │
    │       YES ──► call sign-video-url Edge Fn (no auth check needed)
    │
    └── NO ──► RevenueCat.getCustomerInfo()
                    │
                    ├── has "premium" entitlement?
                    │       │
                    │       YES ──► call sign-video-url Edge Fn
                    │                   (Edge Fn re-verifies server-side)
                    │                       │
                    │                       └── return signed CF URL (~1h TTL)
                    │                               │
                    │                               └── AVPlayer(url:) ──► play
                    │
                    └── NO ──► show PaywallSheet

sign-video-url Edge Function (Deno):
    ├── Verify Supabase JWT (user is authenticated)
    ├── Check lesson.is_free_preview OR profiles.is_subscribed
    ├── If authorized: sign CF URL with CF_SIGNING_SECRET (env var)
    └── Return { url: "https://..." } with 1h expiry
```

### IAP / Subscription
```
PaywallSheet presented
    │
    └── RevenueCat.purchase(package:)
            │
            └── StoreKit 2 sheet (Apple)
                    │
                    └── User confirms ──► receipt → RevenueCat servers
                                            │
                                            └── RevenueCat webhook → Supabase
                                                    │
                                                    └── UPDATE profiles
                                                        SET is_subscribed = true
                                                        WHERE id = user_id
```

---

## File Structure

```
Tantrika/
├── TantrikaApp.swift              # App entry, DI container
├── Models/
│   ├── Course.swift
│   ├── Lesson.swift
│   ├── UserProgress.swift
│   └── UserProfile.swift
├── Services/
│   ├── SupabaseServiceProtocol.swift
│   ├── SupabaseService.swift      # Live Supabase client
│   ├── MockSupabaseService.swift  # For tests
│   ├── EdgeFunctionServiceProtocol.swift
│   ├── EdgeFunctionService.swift
│   ├── RevenueCatServiceProtocol.swift
│   └── RevenueCatService.swift
├── ViewModels/
│   ├── AuthViewModel.swift
│   ├── LibraryViewModel.swift
│   ├── PlayerViewModel.swift
│   └── PaywallViewModel.swift
├── Views/
│   ├── Auth/
│   │   └── AuthView.swift
│   ├── Library/
│   │   ├── LibraryView.swift
│   │   └── CourseDetailView.swift
│   ├── Player/
│   │   └── PlayerView.swift
│   └── Paywall/
│       └── PaywallView.swift
└── EdgeFunctions/               # Supabase Edge Function source
    └── sign-video-url/
        └── index.ts             # Deno, ~30 lines

TantrikaTests/
├── LibraryViewModelTests.swift
├── PlayerViewModelTests.swift
├── AuthViewModelTests.swift
└── EdgeFunctionServiceTests.swift

TantrikaUITests/
├── AuthFlowUITests.swift
├── LibraryBrowseUITests.swift
└── VideoPlaybackUITests.swift
```

---

## Supabase Edge Function — sign-video-url

```typescript
// supabase/functions/sign-video-url/index.ts
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CF_ACCOUNT_ID = Deno.env.get("CF_ACCOUNT_ID")!;
const CF_SIGNING_KEY_ID = Deno.env.get("CF_SIGNING_KEY_ID")!;
const CF_SIGNING_SECRET = Deno.env.get("CF_SIGNING_SECRET")!; // NEVER in app binary

Deno.serve(async (req) => {
  const { lessonId } = await req.json();

  // 1. Verify JWT
  const supabase = createClient(...);
  const { data: { user }, error } = await supabase.auth.getUser(
    req.headers.get("Authorization")?.replace("Bearer ", "") ?? ""
  );
  if (error || !user) return new Response("Unauthorized", { status: 401 });

  // 2. Fetch lesson
  const { data: lesson } = await supabase
    .from("lessons").select("cf_video_id, is_free_preview").eq("id", lessonId).single();

  // 3. Check access
  if (!lesson.is_free_preview) {
    const { data: profile } = await supabase
      .from("profiles").select("is_subscribed").eq("id", user.id).single();
    if (!profile.is_subscribed) return new Response("Forbidden", { status: 403 });
  }

  // 4. Sign Cloudflare Stream URL (1h TTL)
  const signedUrl = await signCloudflareUrl(lesson.cf_video_id, 3600);
  return Response.json({ url: signedUrl });
});
```

---

## Performance Notes

- **Prefetch on open:** single `SELECT courses.*, lessons.*` joined query. Sufficient for v1
  with small library. Add `lessons(course_id)` index.
- **Progress writes:** every 10s via AVPlayer `addPeriodicTimeObserver`. Writes on background
  Task. Silent failures are a known v1 limitation (see TODOS.md TODO-002).
- **Thumbnail loading:** use `AsyncImage` with `.resizable()` + disk cache from URLSession.

---

## Responsive & Accessibility

### Orientation
- **AuthView, LibraryView, CourseDetailView, PaywallView:** Portrait-only (`UIInterfaceOrientationMask.portrait`).
- **PlayerView:** Portrait + landscape (`UIInterfaceOrientationMask.allButUpsideDown`). AVKit native landscape support handles this automatically. Lock back to portrait on PlayerView dismiss.

### Accessibility
- **Touch targets:** All interactive elements minimum 44×44pt. Lesson rows: full-width tap target (not just the thumbnail).
- **VoiceOver labels:** Every `Image` gets an explicit `.accessibilityLabel`. Course cards: "Course: [title], [N] lessons, [locked/unlocked]". Lesson rows: "[title], [duration], [Members only / Free preview / Completed]".
- **Dynamic Type:** Support up to `.accessibilityXXXL`. Use `.font(.body)` semantic styles on body/caption text, not fixed sizes. Cormorant Garant headings: use `.font(.custom("CormorantGarant-Regular", size: 24, relativeTo: .title))` to enable scaling.
- **Color contrast:** `tantrikaText` (#2C1A12) on `tantrikaBackground` (#FAF6F1) = 10.8:1 (AAA). `tantrikaAccent` (#C4624A) on white = 3.8:1 (AA for large text). Do NOT use `tantrikaSecondary` (sage) as text on light background — contrast fails at small sizes.
- **Reduce Motion:** Respect `UIAccessibility.isReduceMotionEnabled`. If true: disable skeleton shimmer animation (show static placeholders), disable auto-advance countdown animation (immediate transition with confirmation).
- **Content sensitivity:** Tantra content may be sensitive. No explicit content in thumbnails or screenshots (App Store compliance). Thumbnails should show teacher, practice settings, or abstract imagery — not bodies.

---

## Design System

### Color Palette
```swift
// Define as SwiftUI Color extensions — never use hardcoded hex inline
extension Color {
    static let tantrikaBackground  = Color(hex: "#FAF6F1")  // warm off-white
    static let tantrikaAccent      = Color(hex: "#C4624A")  // terracotta (primary CTA)
    static let tantrikaText        = Color(hex: "#2C1A12")  // deep warm brown
    static let tantrikaSecondary   = Color(hex: "#8A9E85")  // muted sage (accents, badges)
    static let tantrikaSurface     = Color(hex: "#F0E8DE")  // warm cream (cards, sheets)
    static let tantrikaTextMuted   = Color(hex: "#7A6355")  // muted brown (captions, metadata)
}
```
**NOT in palette:** system blue, purple/violet, cold grays. If you find yourself using `.blue` or `.purple` anywhere, that's a bug.

### Typography Scale
```
DISPLAY  (48pt): Cormorant Garant Light   — AuthView value proposition, course hero title
HEADING  (24pt): Cormorant Garant Regular — Screen titles, course names
SUBHEAD  (17pt): SF Pro Display Semibold  — Section headers, lesson titles
BODY     (15pt): SF Pro Text Regular      — Descriptions, metadata
CAPTION  (13pt): SF Pro Text Regular      — Duration, completion state, badge text
BUTTON   (16pt): SF Pro Text Semibold     — CTAs (SF Pro, not Cormorant, for legibility)
```

**Implementation:** Bundle Cormorant Garant OTF files in the app target. Available free from Google Fonts. Register in `Info.plist` as `UIAppFonts`.

### Locked Content Treatment
- **Locked lessons:** Render at full opacity. Show a small "Members only" pill badge (terracotta background, white caption text) on the lesson row. No lock icon, no blur, no opacity reduction.
- **PaywallView trigger:** Tapping a locked lesson anywhere presents `PaywallView` as a sheet.
- **Free preview lessons:** Show a "Free preview" pill badge (sage green background, white caption text).

### Component Vocabulary
- **Buttons:** Rounded rectangle, `tantrikaAccent` fill, white SF Pro Semibold label. Corner radius: 12pt.
- **Cards (course/lesson rows):** `tantrikaSurface` background. Subtle shadow: `y: 2, blur: 8, color: tantrikaText.opacity(0.08)`. Corner radius: 16pt.
- **Sheets:** `tantrikaBackground` background. Standard iOS sheet presentation (detent: `.large`).
- **Teacher hero:** Circle avatar image (60pt diameter) with `tantrikaAccent` ring border (2pt). Name in SUBHEAD style.
- **Progress indicator:** Thin bar (4pt height), `tantrikaAccent` fill over `tantrikaSurface` track.

### Anti-slop rules for this project
- No purple, violet, or blue in the palette. Ever.
- No 3-column symmetric feature grids.
- No generic meditation app visuals (mandalas, lotus, generic sacred geometry).
- No emoji in UI copy.
- No centered text on catalog/list screens — left-aligned only.
- Astiko's photo (real, warm-toned) is preferred over illustration placeholders.

---

## User Journey & Emotional Arc

```
STEP | USER ACTION                  | USER FEELS            | APP RESPONSE
-----|------------------------------|-----------------------|----------------------------------------
1    | App opens for first time     | Curious, cautious     | AuthView: branded splash with Astiko
     |                              |                       | image + value line. Warm, not clinical.
2    | Signs in with Apple          | Committed enough      | Smooth transition → LibraryView
     |                              | to try                |
3    | Sees LibraryView             | Exploring             | Teacher hero + courses. Astiko present.
     |                              |                       | Most content shows but locked lessons
     |                              |                       | have subtle lock indicator (not walls).
4    | Taps a course                | Interested            | CourseDetailView: course art, description,
     |                              |                       | "Start Free Preview" as hero CTA.
5    | Watches free preview         | Experiencing          | PlayerView full-screen. Astiko's voice.
     |                              | Astiko's teaching     | Native controls. Lesson title fades.
6    | Video auto-advances          | Engaged or ready      | 3-second countdown to next free lesson
     |                              | to stop               | (or course end if only 1 free lesson).
     |                              |                       | Cancel visible. No pressure.
7    | Hits a paid lesson           | Considering paying    | PaywallView sheet: headline + pricing.
     |                              |                       | "Start free preview instead" option
     |                              |                       | available — not a hard wall.
8    | Subscribes                   | Committed             | Sheet dismisses. Content unlocks silently.
     |                              |                       | CourseDetailView now shows all lessons.
9    | Watches first paid lesson    | Initiated             | Same PlayerView. Progress tracked.
     |                              |                       | Auto-advance enabled across full course.
10   | Returns to app next session  | Belonging             | LibraryView: teacher hero + progress
     |                              |                       | state visible (e.g. lesson X of Y done).
```

**Design principles for emotional arc:**
- Never show a "locked content wall" as first impression — the free preview CTA is always reachable.
- Astiko's photo appears on AuthView, LibraryView hero, and PaywallView — three times across the core funnel. The teacher is consistently present.
- The transition from exploring to paying should feel like opening a door, not bypassing a gate.
- Post-subscribe: just dismiss (v1). Welcome modal deferred to v1.1 (see TODOS.md).

---

## Interaction States

```
SCREEN              | LOADING              | EMPTY               | ERROR                    | SUCCESS               | PARTIAL
--------------------|----------------------|---------------------|--------------------------|----------------------|--------
AuthView            | —                    | —                   | "Couldn't sign in.       | → LibraryView         | —
                    |                      |                     |  Try again." + retry btn |                      |
LibraryView         | Skeleton cards       | "Coming soon —      | "Couldn't load lessons.  | Courses + teacher     | Show cached
                    | (shimmer animation)  |  check back soon."  |  Pull to refresh."       | hero rendered        | data + refresh
CourseDetailView    | Skeleton lesson rows | —                   | "Couldn't load course.   | Lesson list + CTA     | —
                    |                      |                     |  Go back."               |                      |
PlayerView          | AVKit native buffer  | —                   | "Video unavailable.      | Plays immediately     | Resumes at
(loading video)     | spinner (acceptable) |                     |  Check connection."      | at watched_seconds   | watched_seconds
PlayerView          | —                    | —                   | "Couldn't save progress. | (silent, background)  | —
(progress save)     |                      |                     |  (silent, toast log)"    |                      |
PaywallView         | Disable CTA button,  | —                   | "Purchase failed.        | Dismiss sheet →       | —
                    | show spinner in btn  |                     |  [Apple error message]   | LibraryView with      |
                    |                      |                     |  Try again."             | content unlocked      |
```

**Specific state notes:**
- **Video buffer:** AVKit's native spinner is acceptable for v1. Do NOT show a custom overlay — AVKit manages buffering state internally and a custom overlay creates a flicker.
- **Purchase failure:** Show Apple's raw StoreKit error message (localised by Apple). Do NOT write custom error copy — Apple's purchase errors are already user-friendly.
- **Progress save failure:** Silent. Log to console. Do NOT surface to user for a background write failure (too noisy). v1.1 adds retry queue.
- **Resume position:** PlayerView always starts at `watched_seconds` if > 30s. No prompt. Silent resume. Under 30s = start from beginning.
- **First-time open (no courses yet):** LibraryView empty state: teacher hero still shows. Below it: "Astiko is preparing the first lessons. Check back soon." with a soft illustration placeholder.
- **Auth failure (Apple sign-in network error):** "Couldn't connect to sign in. Check your connection and try again." + retry button. Keep branded background visible.

---

## Screen Design Decisions

### AuthView
**Architecture:** Auth-first (sign-in required before content). Known tradeoff: conversion loss at door.
**Hierarchy:** NOT a plain login screen. Branded splash experience:
1. Tantrika wordmark / logo (top)
2. Hero image — Astiko (full-bleed or large portrait, warm tone)
3. One-line value proposition: e.g. "Ancient wisdom for the modern body."
4. Sign in with Apple button (primary CTA, bottom third)

### LibraryView
**Architecture:** Teacher hero at top, course catalog below.
**Layout:** Vertical list (single column). Full-width course cards — NOT a grid.
**Hierarchy:**
1. Teacher hero row: Astiko photo (circle, 60pt, `tantrikaAccent` ring) + name in SUBHEAD style + 1-sentence greeting
2. "New this week" highlight (1 featured course row, if content warrants — same card style, subtle `tantrikaAccent` left bar)
3. Course list: `List` or `ScrollView + LazyVStack` of full-width course cards
**Course card anatomy (full-width):**
```
┌──────────────────────────────────────────────┐
│ [Thumbnail 80×80pt] [Course Title — SUBHEAD]  │
│ [tantrikaSurface bg] [1-line description BODY]│
│                      [N lessons · X hrs CAPTION]│
│                      [Members only badge? CAPTION]│
└──────────────────────────────────────────────┘
```
Corner radius: 16pt. Shadow: y:2, blur:8, `tantrikaText.opacity(0.08)`.

### CourseDetailView
**Architecture:** Context-sensitive CTA based on subscription status.
- **Non-subscriber:** Primary CTA = "Start Free Preview" (lesson 1). Secondary = sticky "Subscribe to Unlock All" footer banner.
- **Subscriber:** Primary CTA = "Continue" (resume last-watched lesson). No lock UI.
**Hierarchy:**
1. Course cover image (full-width header, ~200px)
2. Course title + description (2-3 lines)
3. Primary CTA button
4. Lesson list (numbered, with duration, completion checkmark for subscribers)

### PlayerView
**Architecture:** AVKit native player. Post-video: auto-advance to next lesson (3s countdown, cancellable).
**Hierarchy during playback:**
1. Full-screen video (AVKit standard controls)
2. Lesson title overlay (top, fades after 3s)
3. Progress indicator (bottom, shows position in course)
**Post-video state:** 3-second countdown → auto-advance to next lesson. Cancel button visible during countdown. Last lesson in course: return to CourseDetailView.
**Resume behavior:** If user left mid-lesson, PlayerView resumes at last `watched_seconds` position (no prompt, silent resume).

### PaywallView (sheet)
**Architecture:** Bottom sheet presented over CourseDetailView when non-subscriber taps locked lesson.
**Hierarchy:**
1. Value headline: "Unlock Astiko's full library"
2. Pricing: monthly + annual options (annual highlighted as "Best Value")
3. Subscribe CTA (primary)
4. "Start free preview instead" (secondary, if free lesson exists in this course)
5. Dismiss chevron (top)

---

## NOT in scope (v1)

| Item | Rationale |
|------|-----------|
| FairPlay DRM | Ships faster; signed URLs sufficient for trusted community launch. See TODOS.md. |
| Email/password auth | Apple Sign-In covers the target audience for v1. |
| Progress retry queue | Simple Supabase-only for v1. See TODOS.md. |
| Live sessions / Zoom integration | v2 feature |
| In-app messaging / community forum | v2 feature |
| Web app / Android | iOS first |
| Admin content upload UI | Astiko uploads directly via Cloudflare Stream dashboard for v1 |
| Multiple teachers | v2 |
| Offline video download | Complex, deferred |

---

## What already exists

| Component | Status |
|-----------|--------|
| AVKit / AVFoundation | Built into iOS — use directly, don't wrap |
| StoreKit 2 | Built into iOS — RevenueCat wraps it |
| Keychain | Built into iOS — Supabase Swift SDK handles JWT storage |
| XCTest / XCUITest | Scaffolded by Xcode in TantrikaTests/ and TantrikaUITests/ |
| Xcode project | Scaffolded — ready to add SPM dependencies |

---

## Distribution

1. **TestFlight:** Set up App Store Connect record + provisioning before first build.
2. **Dependencies (SPM):**
   - `github.com/supabase/supabase-swift`
   - `github.com/RevenueCat/purchases-ios`
3. **App Store requirements:**
   - Sign in with Apple (entitlement + capability)
   - Privacy manifest (required for apps using third-party SDKs)
   - In-app purchase products configured in App Store Connect

---

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — | — |
| Codex Review | `/codex review` | Independent 2nd opinion | 0 | — | — |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | CLEAR | 9 issues, 0 critical gaps |
| Design Review | `/plan-design-review` | UI/UX gaps | 1 | CLEAR | score: 2/10 → 9/10, 11 decisions made |

**VERDICT:** ENG + DESIGN CLEARED — 11 design decisions added to plan, 2 design TODOs captured. Run `/design-consultation` before UI implementation to produce DESIGN.md.
