# Tantrika — Claude Code Instructions

## Project Overview
iOS native app (SwiftUI, iOS 17+). Paid subscription video platform for a single Tantra teacher (Astiko). Users subscribe monthly or annually to access video lessons.

**5 screens:** AuthView, LibraryView, CourseDetailView, PlayerView, PaywallView.

See `PLAN-v1.md` for full architecture, data model, and key flows.
See `DESIGN.md` for the complete design system (MUST read before any UI work).
See `TODOS.md` for deferred items with context.
See `SETUP.md` for Xcode setup checklist (SPM packages, Supabase schema, RevenueCat).

---

## Stack

| Layer | Technology |
|-------|-----------|
| iOS framework | SwiftUI + @Observable (iOS 17+) |
| Architecture | MVVM + async/await, protocol-DI |
| Backend/DB | Supabase (PostgreSQL + RLS + Auth) |
| Auth | Supabase Auth + Sign in with Apple |
| Video CDN | Cloudflare Stream (HLS + signed URLs) |
| Edge compute | Supabase Edge Function (Deno) — video URL signing |
| IAP | RevenueCat + StoreKit 2 |
| DRM | Deferred to v1.1 (see TODO-003) |

**SPM dependencies:**
- `github.com/supabase/supabase-swift`
- `github.com/RevenueCat/purchases-ios`

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
│   ├── Auth/AuthView.swift
│   ├── Library/LibraryView.swift
│   ├── Library/CourseDetailView.swift
│   ├── Player/PlayerView.swift
│   └── Paywall/PaywallView.swift
└── EdgeFunctions/
    └── sign-video-url/index.ts    # Deno, ~30 lines

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

## Build & Run

Open `Tantrika.xcodeproj` in Xcode. Run on simulator or device.

**Before first build**, complete all steps in `SETUP.md`:
1. Add SPM packages (supabase-swift, purchases-ios)
2. Bundle Cormorant Garant OTF fonts + register in Info.plist
3. Set Info.plist keys: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `REVENUECAT_API_KEY`
4. Set up Supabase database tables + RLS + trigger (SQL in SETUP.md)
5. Deploy `sign-video-url` Edge Function with Cloudflare secrets
6. Configure RevenueCat entitlements and App Store Connect products
7. Add Sign in with Apple capability in Xcode

---

## Data Model

```
profiles         — id (FK auth.users), is_subscribed bool, created_at
courses          — id, title, description, thumbnail_url, sort_order
lessons          — id, course_id, title, cf_video_id, duration_secs, sort_order, is_free_preview
user_progress    — (user_id, lesson_id) PK, watched_seconds, completed, updated_at
```

RLS is enforced at the database level. The `sign-video-url` Edge Function re-verifies authorization server-side — never trust client-only checks for gated content.

---

## Key Architectural Rules

### Services are protocol-based
All services (`SupabaseService`, `EdgeFunctionService`, `RevenueCatService`) conform to protocols. Inject via DI in `TantrikaApp.swift`. Use `MockSupabaseService` in tests — never hit real Supabase in unit tests.

### Subscription access checking
- **v1:** `PlayerViewModel.prepareVideo()` checks `profiles.is_subscribed` (Supabase) AND `RevenueCat.getCustomerInfo()` entitlements.
- The `sign-video-url` Edge Function is the authoritative gatekeeper — it verifies JWT + `profiles.is_subscribed` server-side.
- **Known limitation (TODO-001):** Missed webhooks (refund, expiry) can leave `is_subscribed = true` stale. v1.1 fix: query RevenueCat REST API server-to-server in Edge Function.

### Video playback
- Use `AVKit`/`AVFoundation` directly — do not wrap with a custom player.
- Always request a signed URL from the Edge Function before initializing `AVPlayer`. Signed URLs expire after 1 hour.
- Resume position: if `watched_seconds > 30`, seek to it on load. No prompt. Silent.
- Progress writes: `addPeriodicTimeObserver` every 10s on a background Task. Silent failures are a known v1 limitation (TODO-002).

### Orientation
- All screens except PlayerView: portrait-only (`UIInterfaceOrientationMask.portrait`).
- PlayerView: all orientations except upside-down. Lock back to portrait on dismiss.

### Paywall flow
- Locked lesson tap → present `PaywallView` as `.sheet` (detent: `.large`).
- Always offer "Start free preview instead" as a secondary action if a free lesson exists.
- Post-subscribe: dismiss sheet silently. Welcome modal deferred to v1.1 (TODO-004).

---

## Design System

**Always read `DESIGN.md` in full before any UI work. The rules below are a summary only.**

### Colors (never hardcode hex inline — use these extensions)
```swift
extension Color {
    static let tantrikaBackground = Color(hex: "#F5F0EA")  // Parchment — dominant on every screen
    static let tantrikaSurface    = Color(hex: "#EDE5D8")  // Warm Cream — cards, sheets
    static let tantrikaAccent     = Color(hex: "#C4624A")  // Terracotta — PRIMARY CTA ONLY (precious)
    static let tantrikaText       = Color(hex: "#2C1A12")  // Deep Brown — primary text
    static let tantrikaTextMuted  = Color(hex: "#7A6355")  // Muted Brown — captions, metadata
    static let tantrikaSage       = Color(hex: "#8A9E85")  // Sage — Free preview badge ONLY
}
```

### Typography
| Role | Font | Size |
|------|------|------|
| Display | Cormorant Garant Light | 48pt |
| Heading | Cormorant Garant Regular | 24pt |
| Subhead | SF Pro Display Semibold | 17pt |
| Body | SF Pro Text Regular | 15pt |
| Caption | SF Pro Text Regular | 13pt |
| Button | SF Pro Text Semibold | 16pt |

### Layout constants
- Horizontal margins: **32pt** (never the iOS default 16-20pt)
- Cards: `tantrikaSurface` bg, `cornerRadius: 16`, shadow `y:2 blur:8 tantrikaText@8%`
- Buttons: `tantrikaAccent` fill, white label, `cornerRadius: 12`, 14pt vertical padding
- Badges: pill (`cornerRadius: 9999`) — "Members only" in terracotta, "Free preview" in sage

### Hard rules (reject in code review if violated)
1. No `.blue`, `.purple`, violet, or cold colors anywhere.
2. No progress gamification on visible surfaces (no streaks, completion rings, badges on teacher hero).
3. No centered text on catalog/list screens (left-aligned only; AuthView hero is the only exception).
4. No decorative gradients.
5. No emoji as UI elements.
6. No generic meditation imagery (mandalas, lotus, sacred geometry).
7. No 3-column symmetric feature grids.
8. Terracotta is used ONLY on: primary CTA buttons, "Members only" badge, teacher avatar ring, active tab indicator, progress fill.
9. `tantrikaSage` is NEVER used as text color — contrast fails.
10. All `Image` views require `.accessibilityLabel`.

### Dark mode
Parchment → `#1E1510`, Surface → `#2A1E16`, Text → `#F5EDE0`, TextMuted → `#A8917E`. Accent stays the same.

### Motion
Cross-dissolve only, 0.25s ease-out. Never: bounce, spring physics on content, scale entrance animations. When `UIAccessibility.isReduceMotionEnabled`: remove all animations, show static skeleton placeholders, auto-advance becomes a confirmation dialog.

---

## Interaction States

| Screen | Loading | Error |
|--------|---------|-------|
| LibraryView | Skeleton shimmer cards | "Couldn't load lessons. Pull to refresh." |
| CourseDetailView | Skeleton lesson rows | "Couldn't load course. Go back." |
| PlayerView (video) | AVKit native buffer spinner | "Video unavailable. Check connection." |
| PlayerView (progress save) | — | Silent (log only — never surface to user) |
| PaywallView | Spinner in CTA button | Show Apple's StoreKit error verbatim |
| AuthView | — | "Couldn't connect to sign in. Check your connection and try again." |

- **Resume:** PlayerView always starts at `watched_seconds` if > 30s, no prompt.
- **Progress save failure:** Silent. Log to console. Do NOT show to user. (TODO-002 for retry queue.)
- **Purchase failure:** Show Apple's raw StoreKit error — do NOT write custom copy.
- **AVKit buffer:** Use AVKit's native spinner — no custom overlay (causes flicker).

---

## Accessibility

- Touch targets: 44×44pt minimum. Lesson rows: full-width tap target.
- VoiceOver: every `Image` needs `.accessibilityLabel`. Course cards: "Course: [title], [N] lessons, [locked/unlocked]". Lesson rows: "[title], [duration], [Members only / Free preview / Completed]".
- Dynamic Type: use `.relativeTo:` on Cormorant Garant fonts. Test up to `.accessibilityXXXL`.
- Content sensitivity: no explicit content in thumbnails or App Store screenshots.

---

## v1 Scope Boundaries

**Not in v1** — do not implement unless explicitly requested:
- FairPlay DRM (TODO-003)
- Email/password auth
- Progress write retry queue (TODO-002)
- Post-subscribe welcome modal (TODO-004)
- Live sessions, community forum, web app, Android, admin upload UI, multiple teachers, offline download

---

## QA Mode

When reviewing code for design compliance, flag any violation of `DESIGN.md`. Key checks:
- Background is `#F5F0EA`, not white.
- No hardcoded hex values — use `Color.tantrika*` extensions.
- No `.blue`, `.purple` anywhere.
- Horizontal margins are 32pt.
- Cormorant Garant only for Display/Heading roles.
- Terracotta used sparingly and only in approved locations.
