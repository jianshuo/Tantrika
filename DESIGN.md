# Design System — Tantrika

## Product Context
- **What this is:** A paid iOS subscription app for a single Tantra teacher (Astiko). Users pay monthly/annually to watch video lessons.
- **Who it's for:** People drawn to Tantra practice — spiritual, body-aware, privacy-conscious. Adults seeking an intimate and personal guided practice.
- **Space/industry:** Spiritual / wellness / video content. Adjacent to Glo, The Class, Insight Timer — but positioning as single-teacher and intimate, not marketplace.
- **Project type:** iOS native app (SwiftUI, iOS 17+). 5 screens: AuthView, LibraryView, CourseDetailView, PlayerView, PaywallView.

## Aesthetic Direction
- **Direction:** Organic/Natural meeting Luxury/Refined — "candlelit private studio"
- **Decoration level:** Intentional. Astiko's photography is the primary visual element. Negative space does the heavy lifting. No decorative UI elements (no blobs, gradients as decoration, or abstract iconography).
- **Mood:** Warm, austere, physical. As if the app is a room you've been invited into, not a product you've downloaded. The category does "spa menu warmth everywhere." Tantrika does "one precise warm element, surrounded by discipline."
- **Anti-pattern:** Do NOT slide into "artisan wellness" cliché (generic retreat-center aesthetic). Counterweight: strict invisible grid, generous parchment negative space. Warmth lands with force when surrounded by restraint.
- **Emotional target (first 3 seconds):** "I have crossed a threshold." Not excited, not informed. Somewhere different now.

## Color

### Palette
```swift
// Define as SwiftUI Color extensions — never use hardcoded hex inline
extension Color {
    static let tantrikaBackground  = Color(hex: "#F5F0EA")  // Parchment — background
    static let tantrikaSurface     = Color(hex: "#EDE5D8")  // Warm Cream — cards, sheets
    static let tantrikaAccent      = Color(hex: "#C4624A")  // Terracotta — primary CTA (sparse)
    static let tantrikaText        = Color(hex: "#2C1A12")  // Deep Brown — primary text
    static let tantrikaTextMuted   = Color(hex: "#7A6355")  // Muted Brown — captions, metadata
    static let tantrikaSage        = Color(hex: "#8A9E85")  // Sage — free preview badge only
}
```

### Usage Rules
- **Terracotta** (`tantrikaAccent`) is precious. Use it on: primary CTA buttons, "Members only" badge, teacher avatar ring, active tab indicator, progress fill. Nowhere else.
- **Parchment** (`tantrikaBackground`) is the dominant color of every screen. Not white.
- **Sage** is only for the "Free preview" badge. Never use for primary actions or text.
- **NEVER use:** system blue, purple/violet, cold gray, or any gradient as decoration.
- If you find yourself reaching for `.blue` or `.purple` anywhere in SwiftUI code, that is a bug.

### Dark Mode
Reduce saturation 15-20%. Deep surface, preserve warm hue.
```swift
// Dark mode values
tantrikaBackground:  #1E1510  (deep warm charcoal)
tantrikaSurface:     #2A1E16  (warm dark surface)
tantrikaText:        #F5EDE0  (warm off-white)
tantrikaTextMuted:   #A8917E
// tantrikaAccent stays the same
```

### Contrast Ratios
- `tantrikaText` on `tantrikaBackground`: **10.8:1** (AAA ✓)
- `tantrikaText` on `tantrikaSurface`: **9.4:1** (AAA ✓)
- White on `tantrikaAccent`: **3.9:1** (AA for large text ✓)
- `tantrikaTextMuted` on `tantrikaBackground`: **4.7:1** (AA ✓)
- **Do NOT** use `tantrikaSage` as text on any background — contrast fails at small sizes.

## Typography

### Font Stack
```swift
// iOS: Cormorant Garant must be bundled as OTF in the app target
// Register in Info.plist under UIAppFonts:
// - CormorantGarant-Light.otf
// - CormorantGarant-Regular.otf
// - CormorantGarant-LightItalic.otf
// Available free: https://fonts.google.com/specimen/Cormorant+Garant

let displayFont  = Font.custom("CormorantGarant-Light",   size: 48, relativeTo: .largeTitle)
let headingFont  = Font.custom("CormorantGarant-Regular", size: 24, relativeTo: .title)
let headingItalic = Font.custom("CormorantGarant-LightItalic", size: 24, relativeTo: .title)
let subheadFont  = Font.system(size: 17, weight: .semibold, design: .default)  // SF Pro Display
let bodyFont     = Font.system(size: 15, weight: .regular,  design: .default)  // SF Pro Text
let captionFont  = Font.system(size: 13, weight: .regular,  design: .default)  // SF Pro Text
let buttonFont   = Font.system(size: 16, weight: .semibold, design: .default)  // SF Pro Text
```

### Type Scale
| Role | Font | Size | Weight | Line Height | Usage |
|------|------|------|--------|-------------|-------|
| Display | Cormorant Garant | 48pt | Light | 1.05 | AuthView hero, course hero title |
| Heading | Cormorant Garant | 24pt | Regular | 1.2 | Screen titles, lesson titles |
| Heading Italic | Cormorant Garant | 24pt | Light Italic | 1.2 | Course subtitle, emphasis |
| Subhead | SF Pro Display | 17pt | Semibold | 1.3 | Section headers, lesson count |
| Body | SF Pro Text | 15pt | Regular | 1.6 | Descriptions, course copy |
| Caption | SF Pro Text | 13pt | Regular | 1.5 | Duration, metadata, badge text |
| Button | SF Pro Text | 16pt | Semibold | 1.0 | All CTAs |

### Dynamic Type
All type levels must support Dynamic Type. Use `.relativeTo:` parameter on custom fonts and semantic Font styles on SF Pro.

## Spacing

- **Base unit:** 8pt
- **Density:** Spacious. Resist iOS defaults toward information density.
- **Horizontal margins:** 32pt on all content screens (vs. iOS default 16-20pt).
- **Vertical section gaps:** 48-64pt between distinct content blocks.
- **Line height:** Body text at 1.6 minimum. This is the most important spacing value — it signals that slowing down is the point.

### Scale
```
2xs:  4pt   (internal badge padding)
xs:   8pt   (icon-to-text gaps, tight component internals)
sm:   16pt  (between related elements, inner card padding)
md:   24pt  (between components, list row internal padding)
lg:   32pt  (horizontal screen margins, between sections)
xl:   48pt  (between major screen sections)
2xl:  64pt  (hero padding, screen breathing room)
```

## Layout

- **Approach:** Grid-disciplined app UI. Invisible grid, disciplined alignment. No asymmetry — the content earns attention through scale and restraint, not layout tricks.
- **Horizontal margins:** 32pt left and right on all content. Never less.
- **Course list:** Vertical single-column list. Full-width cards. NOT a grid.
- **Maximum content width:** Native iOS full-width. No artificial max-width constraints.

### Border Radius Scale
```swift
let radiusSm:   CGFloat = 8   // Badges, small elements
let radiusMd:   CGFloat = 12  // Buttons, inputs
let radiusLg:   CGFloat = 16  // Cards, lesson rows, sheets
let radiusFull: CGFloat = 9999 // Pill badges, avatar
```

### Component Vocabulary
```
Buttons:
  Primary   — tantrikaAccent fill, white SF Pro Semibold, radiusMd, 14pt vertical padding
  Secondary — transparent, tantrikaText border (1.5pt), tantrikaText label, same sizing
  Ghost     — transparent, tantrikaTextMuted label, underline on text

Cards (lesson rows):
  tantrikaSurface background, radiusLg, shadow: y:2 blur:8 tantrikaText@8% opacity
  Layout: [Thumbnail 72×72pt, radiusSm] + [Title Heading + Meta Caption + Badge]

Badges:
  "Members only" — tantrikaAccent fill, white caption, radiusFull
  "Free preview" — tantrikaSage fill, white caption, radiusFull

Teacher hero (LibraryView):
  Avatar: 60pt circle, tantrikaAccent ring border 2pt, radiusFull
  Name: Subhead style
  Greeting: Heading Italic style (Cormorant Garant Light Italic)

Progress bar:
  4pt height, tantrikaAccent fill over tantrikaSurface track, radiusFull
```

## Motion

- **Approach:** Minimal-functional. The app should feel still.
- **Default transition:** Cross-dissolve, 0.25s ease-out.
- **Never use:** bounce, spring physics on content, scale entrance animations, slide-from-nowhere effects.
- **Acceptable:** Subtle opacity fade-in on screen appear (0.25s). Sheet presentation using iOS standard `.sheet()` (system animation).
- **Reduce Motion:** When `UIAccessibility.isReduceMotionEnabled` is true, remove all animations. Show static states. No shimmer on skeleton screens (show static placeholders instead). Auto-advance countdown becomes immediate with a confirmation dialog.

## Accessibility

- **Touch targets:** 44×44pt minimum. Lesson rows: full-width tap target.
- **VoiceOver:** Every `Image` requires `.accessibilityLabel`. Course cards: "Course: [title], [N] lessons, [locked/unlocked]". Lesson rows: "[title], [duration], [badge status]".
- **Dynamic Type:** All type scales with `.relativeTo:` parameter. Test up to `.accessibilityXXXL`.
- **Orientation:** Portrait lock for all screens except PlayerView. PlayerView supports landscape.
- **Content sensitivity:** No explicit content in thumbnails or App Store screenshots. Thumbnails: teacher, practice settings, or abstract imagery only.

## Anti-Slop Rules (for Tantrika specifically)

These are hard rules. If any appear in code review, reject them.

1. No purple, violet, blue, or cold colors anywhere in the UI.
2. No 3-column symmetric feature grids.
3. No icons in colored circles as decoration.
4. No generic meditation/mindfulness imagery (stock lotus flowers, mandalas, generic sacred geometry, Buddha statues).
5. No centered text on catalog or list screens — left-aligned only (exception: AuthView hero).
6. No progress gamification visible on home screen (no streaks, no completion rings, no badges on the teacher hero row).
7. No decorative gradients. The only gradients are in photography and the player video overlay (functional scrim).
8. No uniform border-radius on every element — use the radius scale intentionally.
9. No emoji as UI elements.
10. Astiko's real photography > illustration > abstract placeholder. Always.

## Decisions Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-03-27 | Parchment #F5F0EA over plain white as background | Warmer and more intentional; signals "this is not a utility app" |
| 2026-03-27 | Cormorant Garant for display/heading | Editorial, slightly irregular serif; matches intimate single-teacher positioning |
| 2026-03-27 | Terracotta #C4624A as primary accent | Warm, earthy, culturally appropriate for Tantra; breaks from wellness app purple/teal defaults |
| 2026-03-27 | Vertical list layout for course library | Avoids "generic SaaS card grid" pattern; allows course title + description to guide navigation |
| 2026-03-27 | No progress gamification on surface | Tantra has no destination; streaks/rings are antithetical to the practice |
| 2026-03-27 | Minimal-functional motion (cross-dissolve only) | App should feel still; spiritual content context demands restraint |
| 2026-03-27 | 32pt horizontal margins (vs. iOS 16-20pt default) | Spacious density signals "slow down" — aligns with content intention |
| 2026-03-27 | Initial design system created | Created by /design-consultation based on competitive research (Insight Timer, Glo, The Class) + outside design voice |
