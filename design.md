---
name: Kinetic Sprint
colors:
  surface: '#faf8ff'
  surface-dim: '#d2d9f4'
  surface-bright: '#faf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f3ff'
  surface-container: '#eaedff'
  surface-container-high: '#e2e7ff'
  surface-container-highest: '#dae2fd'
  on-surface: '#131b2e'
  on-surface-variant: '#464555'
  inverse-surface: '#283044'
  inverse-on-surface: '#eef0ff'
  outline: '#777587'
  outline-variant: '#c7c4d8'
  surface-tint: '#4d44e3'
  primary: '#3525cd'
  on-primary: '#ffffff'
  primary-container: '#4f46e5'
  on-primary-container: '#dad7ff'
  inverse-primary: '#c3c0ff'
  secondary: '#006591'
  on-secondary: '#ffffff'
  secondary-container: '#39b8fd'
  on-secondary-container: '#004666'
  tertiary: '#3130c0'
  on-tertiary: '#ffffff'
  tertiary-container: '#4b4dd8'
  on-tertiary-container: '#d9d8ff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e2dfff'
  primary-fixed-dim: '#c3c0ff'
  on-primary-fixed: '#0f0069'
  on-primary-fixed-variant: '#3323cc'
  secondary-fixed: '#c9e6ff'
  secondary-fixed-dim: '#89ceff'
  on-secondary-fixed: '#001e2f'
  on-secondary-fixed-variant: '#004c6e'
  tertiary-fixed: '#e1e0ff'
  tertiary-fixed-dim: '#c0c1ff'
  on-tertiary-fixed: '#07006c'
  on-tertiary-fixed-variant: '#2f2ebe'
  background: '#faf8ff'
  on-background: '#131b2e'
  surface-variant: '#dae2fd'
typography:
  headline-xl:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.015em
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: -0.005em
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0em
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
    letterSpacing: 0em
  label-mono-md:
    fontFamily: JetBrains Mono
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: -0.01em
  label-mono-sm:
    fontFamily: JetBrains Mono
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.02em
  label-ui:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.01em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-sm: 0.5rem
  margin: 1rem
  margin-lg: 1.5rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

This design system targets fast-moving engineering leads, agile product managers, and cross-functional software teams who rely on high-density data clarity without visual fatigue. The aesthetic marries high-precision utility with a clean, modern, and focused workspace feel reminiscent of contemporary developer ecosystems.

The brand persona is disciplined, razor-sharp, and quietly assertive:
- **Velocity over Friction:** High scannability, rapid triage affordances, and zero decorative noise.
- **Engineered Precision:** Crisp 1px structural outlines, mathematically rigorous spacing, and deliberate status coding that communicates priority instantly.
- **Empowered Focus:** The UI avoids gaudy saturation, maintaining a disciplined neutral canvas that allows operational metrics and ticket lifecycles to command full attention.

Visual cues draw heavily from functional minimalism paired with low-contrast structural outlines and micro-surfacing. Interfaces emphasize tactile clarity through clear border structures, balanced padding, and decisive status taxonomy.

## Colors

The system uses an Indigo-driven core atop a cool Slate neutral matrix, preserving structural clarity for data-dense mobile canvases.

### Primary & Interface Accents
- **Primary Indigo (`#4F46E5`):** Primary interactions, active tab indicators, selected filters, and high-priority action targets.
- **Primary Subdued (`#EEF2FF`):** Background wash for active selections, interactive highlight states, and key metric badges.
- **Secondary Sky (`#0EA5E9`):** Secondary metrics, links, and discovery metadata.

### Agile Status Tokens
Status tokens rely on two-tone pairs (dark glyph/label over a tinted container) to maintain strict accessibility without overwhelming the view:
- **To Do (Backlog / Planned):** Text `#475569`, Background `#F1F5F9`, Border `#E2E8F0`.
- **In Progress (Active Sprint):** Text `#B45309`, Background `#FEF3C7`, Border `#FDE68A`.
- **Done (Shipped / Resolved):** Text `#047857`, Background `#D1FAE5`, Border `#A7F3D0`.
- **Blocker / Critical Overdue:** Text `#B91C1C`, Background `#FEE2E2`, Border `#FECACA`.

### Canvas & Neutral Palette
- **Canvas Base (`#F8FAFC`):** The foundational backdrop for app sheets and list views.
- **Surface Level 1 (`#FFFFFF`):** Base for task cards, bottom sheets, navigation decks, and modals.
- **Surface Level 2 (`#F1F5F9`):** Input containers, nested story metrics, and secondary chips.
- **Border Default (`#E2E8F0`):** Standard 1px card and cell outline.
- **Border Subdued (`#F1F5F9`):** Inner item dividers and sub-block rules.
- **Text Primary (`#0F172A`):** Headlines, task titles, and primary values.
- **Text Secondary (`#475569`):** Descriptions, section summaries, and filter tags.
- **Text Muted (`#94A3B8`):** Story point labels, inactive icons, and metadata timestamps.

## Typography

The type scale combines three distinct typefaces to separate editorial hierarchy, content density, and technical data:
- **Display & Section Headers (Plus Jakarta Sans):** Modern geometric lines with natural humanist curves give titles a confident, refined rhythm without feeling sterile.
- **Application Body & Direct UI (Inter):** Highly legible, engineered for extreme clarity on mobile displays with neutral proportions that support dense task lists.
- **Metric, Story Points & Key Identifiers (JetBrains Mono):** Monospaced numerals and code tags (`SCRUM-402`, story estimates, velocity deltas) ensure fixed alignment and an authentic engineering feel.

Line heights are clamped tightly to prioritize vertical economy on small screens, preventing cards and list items from consuming excessive viewport space.

## Layout & Spacing

The layout is built on a strict 8px vertical and horizontal grid with 4px sub-increments (`space-xs`) for micro-alignments, tag badges, and inner input paddings.

### Mobile & Device Adaptations
- **Screen Margins:** Standard mobile canvas uses `margin` (16px), expanding to `margin-lg` (24px) on tablet and foldable formats.
- **Kanban Columns:** On mobile views, sprint columns snap to horizontal scroll snap carousels showing 88% width of the active column, revealing the next column's edge with an 8px gutter.
- **Touch Targets:** Interactive targets (swatches, issue reassignment icons, sprint toggles) conform to a mandatory minimum area of 44x44px, using intrinsic padding when child elements are smaller.
- **Nested Card Rhythm:** Task cards maintain an internal padding of `space-md` (16px), with internal element groups separated by `space-sm` (8px).

## Elevation & Depth

Visual hierarchy uses clean surface separations and low-contrast ghost borders (`#E2E8F0`) backed by quiet ambient shadows to distinguish active layers without heavy drop shadows.

- **Level 0 (Flat / Canvas):** Applied to screen backgrounds (`#F8FAFC`). No elevation, no border.
- **Level 1 (Resting Cards & List Modules):** Pure white fill (`#FFFFFF`), paired with a 1px uniform outline in `#E2E8F0` and an ultra-subtle ambient shadow: `0px 1px 3px rgba(15, 23, 42, 0.04), 0px 1px 2px rgba(15, 23, 42, 0.02)`.
- **Level 2 (Active Drag State & Popovers):** Elevated task cards in transit or triggered dropdown filters: `0px 8px 20px -4px rgba(15, 23, 42, 0.08), 0px 4px 6px -2px rgba(15, 23, 42, 0.03)` with border shifting to `#CBD5E1`.
- **Level 3 (Modal Bottom Sheets & Action Drawers):** High-level overlay surfaces: `0px -8px 24px -6px rgba(15, 23, 42, 0.12)`, backed by an opaque modal backdrop using `#0F172A` at 40% opacity with a 4px backdrop blur.

## Shapes

The design uses a unified 14px radius across standard interactive modules (cards, buttons, inputs, sheets), creating a friendly, polished aesthetic that balances the technical tone of the app.

- **Standard Elements (14px):** Task cards, inputs, action buttons, filter tags, and quick-sheet dialogs.
- **Nested & Compact Controls (8px - 10px):** Priority pills, assignee avatar thumbnails, and inline code tags.
- **Fully Pill-Shaped (`rounded-full`):** Floating badges, status pills, sprint indicators, and Story Point markers to differentiate static content from actionable rectangular cards.

## Components

### Task / Story Cards
- **Base Architecture:** Background `#FFFFFF`, 1px solid `#E2E8F0`, 14px corner radius, padding 16px.
- **Header Slot:** Issue Key (e.g., `SCRUM-128`) in `label-mono-sm` text color `#94A3B8`, adjacent to a Priority Pill (e.g., Urgent, High, Low) styled with a 3px left indicator line or tinted pill.
- **Body Slot:** Issue Title in `headline-sm` (`Plus Jakarta Sans`), 2-line maximum clamp with trailing ellipsis.
- **Footer Slot:** Left-aligned Story Point Badge (JetBrains Mono, rounded-full, `#F1F5F9` background, `#334155` text) and an Assignee Avatar circle (24x24px, 1.5px white border outline) aligned to the right alongside a subtask status indicator (e.g., `3/5`).

### Status Badges & Pills
- **Geometry:** Height 24px, fully pill-shaped (`rounded-full`), padding 0 10px.
- **Typography:** `label-ui` with uppercase tracking (`+0.04em`).
- **Variants:**
  - *To Do:* Slate gray (`#475569`), background `#F1F5F9`, border 1px solid `#E2E8F0`.
  - *In Progress:* Amber (`#B45309`), background `#FEF3C7`, border 1px solid `#FDE68A`.
  - *Done:* Emerald (`#047857`), background `#D1FAE5`, border 1px solid `#A7F3D0`.
  - *Blocker:* Crimson (`#B91C1C`), background `#FEE2E2`, border 1px solid `#FECACA`.

### Buttons
- **Primary:** Background `#4F46E5`, text `#FFFFFF`, radius 14px, height 48px. Pressed state darkens to `#4338CA`. Subtle focus halo `0 0 0 3px rgba(79, 70, 229, 0.25)`.
- **Secondary / Subdued:** Background `#EEF2FF`, text `#4F46E5`, 14px radius, height 48px.
- **Destructive:** Background `#FEE2E2`, text `#DC2626`, 14px radius.
- **Icon Utility:** 40x40px, rounded-xl (10px), surface `#F8FAFC`, border 1px solid `#E2E8F0`.

### Form Inputs & Floating Fields
- **Container:** Height 56px, background `#FFFFFF`, border 1px solid `#CBD5E1`, radius 14px, horizontal padding 16px.
- **Floating Label:** Resting state sits centered (`body-md`, `#94A3B8`). On focus/value-present, scales to `11px`, moving up to `8px` from top border, transitioning to `#4F46E5`.
- **Focus State:** 1px border `#4F46E5` accompanied by a soft outer glow ring: `0 0 0 3px rgba(79, 70, 229, 0.15)`.

### Bottom Navigation Bar
- **Surface:** Fixed bottom mount, height 64px (excluding device safe-area inset), background `#FFFFFF` with 95% opacity blur (`backdrop-filter: blur(12px)`), top border 1px solid `#E2E8F0`.
- **Active Tab Affordance:** Active icon colored `#4F46E5`, accompanied by an ambient pill-shaped micro-glow or 4px dot indicator directly beneath. Inactive items colored `#94A3B8`.

### Sprint Burn-down & Velocity Micro-Charts
- **Track & Grid:** 1px dotted horizontal baseline in `#E2E8F0`.
- **Guideline (Ideal):** Dotted `#CBD5E1`.
- **Actual Velocity Line:** 2.5px solid `#4F46E5` with `#EEF2FF` area gradient fill fade to transparent base.