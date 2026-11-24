---
name: FocusTracker
description: Calibrated dark-first desktop cockpit for deliberate focus sessions, interruption tracking, and visual progress.
colors:
  primary: "#3b82f6"
  primary-hover: "#60a5fa"
  primary-dark: "#172554"
  primary-border: "#1d4ed8"
  accent: "#93c5fd"
  accent-warm: "#f59e0b"
  danger: "#ef4444"
  danger-dark: "#991b1b"
  danger-border: "#7a2525"
  danger-muted: "#f87171"
  success: "#22c55e"
  info: "#60a5fa"
  info-alt: "#2563eb"
  warning: "#fbbf24"
  on-solid: "#ffffff"
  text-primary: "#e2e8f0"
  text-secondary: "#cbd5e1"
  text-muted: "#94a3b8"
  text-dimmed: "#7889a4"
  text-subtle: "#475569"
  surface-0: "#0d0e11"
  surface-1: "#13151a"
  surface-2: "#181b21"
  surface-3: "#1f232b"
  surface-4: "#272c36"
  border: "#2b303b"
  border-dim: "#22262f"
  border-active: "#3b82f6"
  light-primary: "#2563eb"
  light-surface-0: "#f8fafc"
  light-surface-1: "#ffffff"
  light-surface-2: "#f1f5f9"
  light-text-primary: "#1e293b"
  light-text-secondary: "#334155"
  light-border: "#cbd5e1"
typography:
  display:
    fontFamily: "Consolas, monospace"
    fontSize: "44px"
    fontWeight: 700
    lineHeight: 1.1
    letterSpacing: "0em"
  headline:
    fontFamily: "Segoe UI, sans-serif"
    fontSize: "26px"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "0em"
  title:
    fontFamily: "Segoe UI, sans-serif"
    fontSize: "22px"
    fontWeight: 700
    lineHeight: 1.25
    letterSpacing: "0em"
  body:
    fontFamily: "Segoe UI, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.4
    letterSpacing: "0em"
  label:
    fontFamily: "Segoe UI, sans-serif"
    fontSize: "12px"
    fontWeight: 500
    lineHeight: 1.3
    letterSpacing: "0.02em"
rounded:
  sm: "6px"
  md: "10px"
  lg: "12px"
  xl: "16px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "20px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-solid}"
    rounded: "{rounded.md}"
    height: "44px"
    padding: "0px 16px"
  button-primary-hover:
    backgroundColor: "{colors.primary-hover}"
    textColor: "{colors.on-solid}"
    rounded: "{rounded.md}"
    height: "44px"
    padding: "0px 16px"
  button-danger:
    backgroundColor: "{colors.danger-dark}"
    textColor: "{colors.on-solid}"
    rounded: "{rounded.md}"
    height: "44px"
    padding: "0px 16px"
  button-ghost:
    backgroundColor: "{colors.surface-4}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.md}"
    height: "44px"
    padding: "0px 16px"
  glass-card:
    backgroundColor: "{colors.surface-2}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.xl}"
    padding: "20px"
  nav-button:
    backgroundColor: "{colors.primary-dark}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.md}"
    height: "44px"
    padding: "0px 14px"
---

# Design System: FocusTracker

## Overview

**Creative North Star: "The Quiet Cockpit"**

FocusTracker is an `Operate`-mode desktop productivity workspace designed to stay calm in peripheral vision while keeping critical session controls immediately legible. Instead of floating drop-shadows or ornamental chrome, the interface relies on neutral obsidian-carbon tonal steps (in dark mode) and crisp slate surfaces (in light mode) framed by hairline borders.

Color carries operational meaning rather than decoration: crisp steel blue (or user-selected accent presets) anchors primary focus actions, emerald signals active progress and unbroken streaks, amber marks cumulative settlement milestones, and saturated red is reserved exclusively for interruption logging and destructive confirmation.

**Key Characteristics:**
- **Tonal surface hierarchy** (`surface0` → `surface4`) paired with crisp 1px borders instead of heavy drop shadows.
- **High-contrast monospace telemetry** (`Consolas`) for live timers so digits never jitter horizontally as seconds tick.
- **Single-stroke Lucide SVG iconography** rendered cleanly through `AppIcon` (`ColorOverlay`) in both light and dark themes.
- **Responsive desktop breakpoints** adapting smoothly from compact 840×560 split windows and 360×90 always-on-top mini windows to 1920px maximized displays.

## Colors

The default dark palette builds depth from neutral obsidian carbon (`#0d0e11`) up to elevated graphite interactive surfaces (`#272c36`), while the light palette pairs slate-tinted backgrounds (`#f8fafc`) with pure white cards (`#ffffff`). All values are served at runtime by `AppTheme` (`app/ui/theme.py`).

### Primary
- **Ocean Steel Blue** (`#3b82f6` dark / `#2563eb` light): Primary action fills (`FTButton` `primary`), active timer ring gradient start, and active filter toggles. Users can override this accent with curated presets (`emerald`, `rose`, `amber`, `cyan`, `violet`).
- **Sky Blue Accent** (`#93c5fd` dark / `#2563eb` light): Active navigation markers, dialog titles, keyboard focus rings, and highlighted metric readouts.
- **Warm Amber** (`#f59e0b` dark / `#d97706` light): Cumulative settlement progression bars, stage headings, and streak stat cards.

### Neutral
- **Obsidian Canvas (`surface-0`)** (`#0d0e11` dark / `#f8fafc` light): Application root window and mini-window background.
- **Carbon Base (`surface-1`)** (`#13151a` dark / `#ffffff` light): Sidebar surface, dropdown popups, tooltips, and modal dialog interiors.
- **Graphite Card (`surface-2`)** (`#181b21` dark / `#f1f5f9` light): Primary `GlassCard` container surface across all pages.
- **Elevated Inset (`surface-3`)** (`#1f232b` dark / `#e2e8f0` light): Progress bar tracks, empty heatmap cells, and text input fields.
- **Interactive Hover (`surface-4`)** (`#272c36` dark / `#cbd5e1` light): Ghost button rest/hover fills, sidebar hover states, and chart tooltip backgrounds.
- **Hairline Border** (`#2b303b` dark / `#cbd5e1` light): Default 1px card and control framing (`border`, `borderDim`, `borderActive`).
- **Primary Ink** (`#e2e8f0` dark / `#1e293b` light): Headings, primary labels, active nav text, and input values.
- **Secondary & Muted Ink** (`#cbd5e1` / `#94a3b8` / `#7889a4` dark; `#334155` / `#475569` / `#64748b` light): Descriptions, card subtitles, timestamps, and metadata calibrated for ≥4.5:1 readability against `surface1`/`surface2`.

### Semantic Status
- **Success Emerald** (`#22c55e` dark / `#16a34a` light): Active session pulse dot, Pomodoro break timer, positive trend indicators, and met goals.
- **Warning Amber** (`#fbbf24` dark / `#d97706` light): Paused state indicators and attention prompts.
- **Info Sky** (`#60a5fa` dark / `#3b82f6` light): Break phase status, duration tags, and secondary chart accents.
- **Danger Crimson** (`#ef4444` dark / `#dc2626` light): "ODAK BOZULDU" action bar, destructive confirmation buttons, and negative trend alerts.

**The Semantic Color Rule.** Never spend red (`danger`) on neutral metadata or amber (`accentWarm`) on ordinary buttons; red means interruption or deletion, and emerald means active/completed focus.

**The Token Authority Rule.** Every surface, border, text, and subject palette color in QML must resolve through `Theme.*` rather than inline hex literals.

## Typography

**Display Font:** `Consolas` (system monospace fallback) for live timers and numeric timecodes.
**Body Font:** Platform UI sans (`Segoe UI` on Windows via Qt default font).
**Label/Mono Font:** `Consolas` for tabular timestamps in session lists and mini-window counters.

**Character:** Compact, pragmatic desktop hierarchy that separates live numeric telemetry from explanatory labels without decorative display serifs.

### Hierarchy
- **Display** (`700`, `44px`, `1.1` line-height): Main `TimerCard` digital readout (`Consolas`).
- **Headline** (`700`, `26px`, `1.2` line-height): `StatCard` primary values and `MiniWindow` countdown readout.
- **Title** (`700`, `22px` / `18px` compact, `1.25` line-height): Page headers (`TrackerPage`, `AnalyticsPage`, `FocusStatsPage`, `HistoryPage`) and modal dialog titles (`17px` DemiBold).
- **Body** (`400`–`500`, `14px`, `1.4` line-height): Button labels, sidebar nav items, subject selector text, and dialog body copy.
- **Label** (`400`–`500`, `12px`, `1.3` line-height): Card subtitles, chart tooltips, metadata rows, and heatmap legend bounds (enforced 12px readability floor).

**The Tabular Timecode Rule.** Live countdowns and elapsed clocks always render in `Consolas` so digit widths never shift horizontally on tick.

**The 12px Floor Rule.** No informational label, tooltip, caption, or chart readout may drop below `12px`.

## Layout

FocusTracker uses a persistent left `Sidebar` paired with a `StackLayout` content canvas (`Main.qml`):
- **Sidebar width:** Collapsible rail between `220px` (expanded with labels) and `68px` (icon-only with hover/focus tooltips), animated over `200ms`.
- **Primary page (`TrackerPage`):** Responsive 2-column `GridLayout` (`16px` column spacing, `8px`–`12px` vertical gap, `16px`–`20px` outer margin) collapsing cleanly to 1 column when `width < 760px`, inside a clipped `ScrollView` so short windows (`height < 650px`) never crop action controls.
- **Analytics & Stats grids:** `StatCard` rows adapt between 4→2 columns (`width < 760px`) or 3→1 columns (`width < 680px`).
- **Mini Window:** Fixed `360×90px` frameless always-on-top cockpit anchored within active screen `availableGeometry`.

## Elevation & Depth

FocusTracker uses **tonal surface layering + crisp 1px borders**, not drop shadows. Cards (`surface2`) sit one step above the app background (`surface0`), while interactive hover surfaces (`surface4`) and modal overlays (`surface1` with a 1px gradient accent frame and `overlayDim` backdrop) communicate hierarchy without GPU blur overhead.

**The Flat-Layering Rule.** Convey depth through surface contrast steps (`surface0` → `surface4`) and hairline borders (`border`, `borderActive`), reserving translucent overlays (`overlayDim`) strictly for modal focus protection.

## Shapes

- **Cards & Dialogs:** Generous rounded rectangles (`16px` radius on `GlassCard` and `FTDialog`, `15px` inner fill inside 1px gradient borders).
- **Buttons, Nav Rows & Mini Window:** Medium-soft corners (`10px` radius on `FTButton` and `NavButton`; `12px` on `MiniWindow`, `distractionBtn`, and compact subject cards).
- **Inputs, Delegates & Tooltips:** Tight functional corners (`8px` on inputs/list items; `6px` on chart tooltips and progress bars; `2px` on heatmap cells).

## Components

### Buttons (`FTButton`)
- **Shape:** Rounded rectangle (`10px` radius), standard `44px` height (`36px`–`42px` in compact toolbars), subtle press scale (`0.97` over `80ms`), `120ms` color transition.
- **Primary:** Solid `Theme.primary` fill with `Theme.onSolid` (`#ffffff`) label/icon and `primaryBorder` stroke.
- **Danger:** Deep crimson (`#991b1b` dark / `#dc2626` light) fill with white content.
- **Ghost:** Elevated surface (`surface4` dark / `#e0e7ff` light) with `textPrimary` content.
- **Hover / Focus:** Lightens/darkens to variant `hover` color; keyboard focus (`activeFocus`) draws a high-contrast `2px` `Theme.accent` ring and reveals any attached tooltip.

### Cards / Containers (`GlassCard`)
- **Corner Style:** `16px` radius.
- **Background:** Solid `Theme.surface2` with `1px` `Theme.border` stroke and optional animated outer `glowOpacity` (`200ms`) on hover (`StatCard`).
- **Internal Padding:** `16px`–`20px` margins (`12px` in compact heights).

### Inputs / Fields
- **Style:** `Theme.surface3` fill, `8px` radius, `1px` `Theme.border` stroke shifting to `Theme.primary` on `activeFocus`, `13px`–`14px` `textPrimary` input text.

### Navigation (`Sidebar` & `NavButton`)
- **Style:** `44px` height pill items (`10px` radius) with a `3px × 24px` vertical `Theme.accent` indicator bar on the left when active, `activeFocusOnTab` support, and automatic `ToolTip` in collapsed (`68px`) rail mode.

### Signature Component (`TimerCard` & `FocusHeatmap`)
- **`TimerCard`:** `240×240` responsive `Canvas` progress ring with `900ms` linear arc smoothing, preset duration selector chips, and `44px` `Consolas` countdown/stopwatch display.
- **`FocusHeatmap`:** Proportional `Canvas` yearly activity matrix with `500ms` fade-in, `0sa–4sa+` intensity legend, and arrow-key keyboard cell inspection (`Accessible.Chart`).

## Do's and Don'ts

### Do:
- **Do** route every color through `Theme.*` tokens and every user-facing string through `Strings.*` (`app/core/strings.py`).
- **Do** give every custom `MouseArea`-backed control `activeFocusOnTab`, `Enter`/`Space` keyboard activation, a visible `activeFocus` border (`2px` `Theme.accent`), and `Accessible.role` / `Accessible.name`.
- **Do** keep `font.pixelSize >= 12` for all readable UI copy, tooltips, badges, and metadata.
- **Do** use single-stroke Lucide SVGs via `AppIcon` so icons recolor cleanly across dark/light themes and accent presets.

### Don't:
- **Don't** hardcode hex colors inside QML pages or dialogs when a `Theme` token or `Theme.subjectColors` belongs there.
- **Don't** use emojis as UI icons or pair semantically misleading icons (like financial trend arrows for window controls).
- **Don't** drop `QT_QUICK_CONTROLS_STYLE=Basic` or rely on heavy drop shadows inside `GlassCard` panels.
- **Don't** convey data intensity in charts (`FocusHeatmap`, `PeriodBarChart`) by color opacity alone without a legend or tooltip/keyboard readout.
