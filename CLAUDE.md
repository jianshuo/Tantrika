# Tantrika — Claude Code Instructions

## Project Overview
iOS native app (SwiftUI, iOS 17+). Paid subscription video platform for a single Tantra teacher (Astiko).

See `PLAN-v1.md` for full architecture, data model, and key flows.
See `TODOS.md` for deferred items with context.

## Design System
Always read `DESIGN.md` before making any visual or UI decisions.
All font choices, colors, spacing, border radii, and aesthetic direction are defined there.
Do not deviate without explicit user approval.

Key design rules:
- Background is parchment `#F5F0EA`, NOT white
- Cormorant Garant for display/heading, SF Pro for everything else
- Terracotta `#C4624A` is precious — only on primary CTAs, badges, avatar ring, progress fill
- Horizontal margins are 32pt (not iOS default 16-20pt)
- No purple, blue, or cold colors anywhere
- No progress gamification on any visible surface

In QA mode, flag any code that doesn't match `DESIGN.md`.

## Stack
- iOS 17+, SwiftUI, MVVM + async/await + @Observable
- Supabase (PostgreSQL + Auth + Edge Functions)
- Cloudflare Stream (HLS video, signed URLs)
- RevenueCat + StoreKit 2 (subscriptions)

## Build Commands
Open `Tantrika.xcodeproj` in Xcode. Run on simulator or device.

## Key Files
- `PLAN-v1.md` — full architecture plan
- `DESIGN.md` — design system (read before any UI work)
- `TODOS.md` — deferred items with context
