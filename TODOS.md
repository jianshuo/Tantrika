# Tantrika — TODOs

## v1.1 (post first paying users)

### TODO-001: Replace `is_subscribed` boolean with live RevenueCat entitlement check
**What:** At video-play time, query RevenueCat SDK `getCustomerInfo()` entitlements directly
instead of reading `profiles.is_subscribed` from Supabase. Edge Function should also verify
via RevenueCat REST API server-to-server.

**Why:** Missed webhooks (refund, expiry, billing lapse) grant permanent free access under
the current boolean-only approach. RevenueCat's SDK caches entitlements locally — it's fast
AND accurate.

**How to apply:** Affects `PlayerViewModel.prepareVideo()` and the `sign-video-url` Edge Function.
Keep `profiles.is_subscribed` as a denormalized cache for analytics, but don't trust it for access.

**Depends on:** RevenueCat SDK integration being stable.

---

### TODO-002: Progress write retry queue
**What:** Add a lightweight write queue (backed by an in-memory array, flushed to UserDefaults
on backgrounding) that retries failed Supabase progress writes.

**Why:** AVPlayer time observer fires every 10s. On a poor connection, writes fail silently.
Users watch a full lesson and have no completion credit — a trust-breaking bug on a paid platform.

**How to apply:** Lives in `ProgressService`. On write failure, enqueue `(lessonId, watchedSeconds, timestamp)`.
Flush queue on next successful write or app foreground.

**~30 lines of code.**

---

### TODO-003: FairPlay DRM
**What:** Add Apple FairPlay Streaming to encrypt video at the CDN level. Requires FPS certificate
from Apple, Cloudflare Stream key server config, and `AVAssetResourceLoaderDelegate` in the iOS app.

**Why:** Screen-recording and HLS manifest extraction bypass signed URL protection entirely.
Adding FairPlay after launch requires re-encoding all content and a forced client update — the
longer this is deferred, the more painful the migration.

**How to apply:** Start FPS certificate request from Apple Developer portal early (can take 3-5 days
for approval). Cloudflare Stream supports FairPlay key server natively. iOS side needs
`AVContentKeySession` + `AVAssetResourceLoaderDelegate`.

**Effort:** ~1-2 weeks. Start certificate process before needing it.

---

## Design TODOs

### TODO-004: Post-subscribe welcome modal
**What:** A single full-screen moment shown once after first subscription: Astiko photo, 2-line welcome message ("Welcome to the practice. You're in the right place."), 'Begin' CTA navigating to the first lesson of the course the user was viewing. Show-once, flagged in UserDefaults (`hasSeenWelcome`).

**Why:** The post-subscribe moment is the highest-stakes emotional beat in the app. Currently it's a flat sheet dismiss. This one screen determines whether users feel they've entered something meaningful or just unlocked a content grid. High retention impact.

**How to apply:** New `WelcomeView` presented full-screen from PaywallViewModel on purchase success. Check `UserDefaults.standard.bool(forKey: "hasSeenWelcome")` — if false, present; set true on dismiss. Navigation: 'Begin' → `PlayerView` with course's first lesson.

**Effort:** ~1 hour (CC-assisted). High value, low cost.

---

### TODO-005: DESIGN.md — formal design system document
**What:** Run `/design-consultation` to produce a `DESIGN.md` capturing the full design system: aesthetic, typography scale, color tokens with usage rules, spacing scale, motion guidelines, and component inventory.

**Why:** Design decisions from the plan review are in `PLAN-v1.md` but scattered. DESIGN.md becomes the single source of truth for every future screen. Without it, each new feature risks drifting from the established language. Also required input for `/design-review` QA on the live app.

**How to apply:** Run `/design-consultation` before writing the first UI View file. Paste in the palette and typography from PLAN-v1.md as starting context.

**Effort:** ~20 minutes. Scheduled: before v1 UI implementation begins.
