# Kidney Care App — Design Guide

This document is the single source of truth for design principles and UI/UX guidelines for the Kidney Care app. It covers both app-wide (global) decisions and page/feature-specific decisions.

## 0. Maintenance Instructions (read this first)

**This is a living document — keep it in sync with the real app at all times.**

- Whenever a new design decision is made — globally (e.g. color palette, typography, spacing, component style, motion) or for a specific page/feature — record it here as part of the same piece of work. Don't defer it to "later."
- Before designing or implementing a new page/feature, check Section 2 (Global Foundations) and Section 3 (Page/Feature-Specific Decisions) here first, so new work stays consistent with what's already been decided.
- If an implementation changes and deviates from what's written here (e.g. a color, spacing value, or pattern is adjusted during build), update this file in the same session — the doc must always reflect actual shipped behavior, not stale intentions.
- Every addition or change to this file should get a dated entry in the Change Log (Section 5), with a one-line reason.
- Prefer adding a new row/entry over rewriting history — if a decision supersedes an older one, note the change in the Change Log rather than silently deleting context.

## 1. Global Design Principles

| Principle | Decision | Notes |
|---|---|---|
| Background color | White | No dark mode for now |
| Font color | Black (mono color) | Single-color text for now; full text-color/contrast system to be revisited later as UX matures |
| Motion/animation | None | No animations for now; will introduce purposeful animation later once core UX is validated |

## 2. Global Foundations

Reusable, app-wide building blocks. Fill these in as they're decided — don't invent values speculatively; add a row only once a decision has actually been made.

Implemented centrally in `app/lib/theme/app_theme.dart` (`AppTheme`) and shared widgets in `app/lib/ui/core/widgets/` — update code and doc together.

### 2.1 Color Palette

| Token | Value | Usage |
|---|---|---|
| `background` | White | Scaffold/page background |
| `ink` | Black | Primary text, icons, borders, filled-button background |
| `error` | `Colors.red.shade700` | Form validation errors only (border + helper text) — first functional/semantic color, introduced because mono black/white can't convey an error state. Rest of the semantic-color question (success/warning/info) is still open, see Section 4. |

Still strictly mono otherwise: no secondary/tertiary/accent color decided yet.

### 2.2 Typography

No custom font family yet (uses Flutter's default Material type). Only override so far:

| Style | Value | Usage |
|---|---|---|
| `headlineMedium` | 28px, bold, `ink` | Screen/section titles (e.g. app name on login, "Welcome back" on home) |
| `titleMedium` | 16px, semibold, `ink` | Card titles (vital summary cards, reading values) |
| `bodyMedium` | 14px, `ink` | Supporting/secondary text (e.g. taglines, timestamps, card descriptions) |
| `optionCardTitle` | 18px, semibold, `ink` | Onboarding signup option titles |

Full type scale (labels, captions, etc.) still TBD — falls back to Material defaults until decided.

### 2.3 Spacing & Layout

4px-based scale, defined as constants on `AppTheme`:

| Token | Value |
|---|---|
| `spacingXs` | 8 |
| `spacingSm` | 16 |
| `spacingMd` | 24 |
| `spacingLg` | 32 |
| `spacingXl` | 40 |

Form/content width on larger screens: constrain to `formMaxWidth: 400` and center, rather than stretching full-width.

Bottom sheets use `sheetTopRadius` (16px top corners only).

### 2.4 Iconography

Using Flutter's built-in Material Icons (outlined style) as placeholders until real iconography/branding is decided — e.g. `Icons.health_and_safety_outlined` stands in for the app logo mark on the login screen. Replace with real brand assets when available; update this doc when that happens.

### 2.5 Components

Shared widgets live in `app/lib/ui/core/widgets/app_components.dart` and `app_form_layout.dart`.

**Buttons**
| Variant | Style | Usage |
|---|---|---|
| Primary (`ElevatedButton`) | Filled `ink` background, `background`-colored text, full-width, 8px corner radius | Main call-to-action per screen (e.g. "Sign In", "Save reading") |
| Secondary (`OutlinedButton` via `AppTheme.secondaryButtonStyle()`) | `ink` border/text, full-width, 8px corner radius | Secondary screen actions (e.g. "View all vitals") |
| Option card (`AppOptionCard` / `AppTheme.optionCardButtonStyle()`) | Outlined, left-aligned row: icon + title + description + chevron | Onboarding signup choices, home vital summaries, vitals hub navigation |
| Text (`TextButton`) | No fill, `ink` text | Tertiary actions (e.g. "Forgot password?", "Sign up") |

**Inputs (`TextFormField`)**
- Outlined border, 8px corner radius, `ink` border (2px when focused).
- Error state: `error`-colored border/text (1px default, 2px when focused+error).
- Inline validation messages shown below the field via `validator`.

**App bar (`AppScreenAppBar`)**
- White background, black foreground, zero elevation — used on all screens with a title/back button.

**Reading card (`AppReadingCard`)**
- Outlined container (`readingCardDecoration`), `spacingSm` padding, value in `titleMedium`, timestamp/notes in `bodyMedium`.

**Empty state (`AppEmptyState`)**
- Centered `bodyMedium` message when a list has no items (e.g. vitals pages before first reading).

**FAB (`FloatingActionButton`)**
- Filled `ink` background, `background` icon — used on vitals pages to add a reading.

**Bottom sheet**
- White background, 16px top corner radius, opens instantly (no slide animation beyond system default sheet behavior).
- Form uses global input/button styles; inline errors use `error` color.

**SnackBar**
- Floating, `ink` background, white text — used for placeholder actions (e.g. "Password reset coming soon").

**Motion**
- Route/page transitions are disabled app-wide (`NoAnimationPageTransitionsBuilder` in `AppTheme`) to match the "no animations for now" principle — navigating between screens is instant, no slide/fade.

## 3. Page / Feature-Specific Decisions

Design decisions that apply to one page or feature rather than the whole app. Add a subsection per page/feature the first time it's designed.

### 3.1 Login Screen

Implemented at `app/lib/ui/features/auth/views/login_view.dart`.

| Element | Decision | Notes |
|---|---|---|
| Scope | Static UI only (sample) | No Supabase auth wiring yet — "Forgot password?" shows a placeholder snackbar. "Sign In" navigates to Home; "Sign up" navigates to Onboarding. Wire to real auth in a later pass. |
| Auth method | Email + Password | Phone/OTP not built for this sample. |
| Layout | Centered, single-column form, no card/border, generous whitespace | Uses `AppFormLayout` + global spacing scale (Section 2.3); constrained to `formMaxWidth: 400` and vertically/horizontally scrollable. |
| Branding | Icon (`Icons.health_and_safety_outlined`) + "Kidney Care" headline + one-line tagline | Icon is a placeholder for a real logo (see Section 2.4). |
| Fields | Email (validated: non-empty, basic email format), Password (validated: non-empty, min 6 chars, show/hide toggle) | Validation runs on submit and on user interaction after first submit (`AutovalidateMode.onUserInteraction`). |
| Extra elements | "Forgot password?" link (right-aligned, above submit), "Sign In" primary button, "Don't have an account? Sign up" (below submit) | See scope row for current navigation behavior. |

### 3.2 Onboarding Screen

Implemented at `app/lib/ui/features/onboarding/views/onboarding_view.dart`.

| Element | Decision | Notes |
|---|---|---|
| Scope | Static UI only | Two signup paths; no backend wiring. |
| Layout | Full-width page padding (`spacingMd`), headline + subtitle, stacked option cards | Uses `AppOptionCard` with 32px icons for signup choices. |
| Options | Patient signup, Caretaker signup | Each card navigates to its respective signup form. |

### 3.3 Patient Signup

Implemented at `app/lib/ui/features/onboarding/views/patient_signup_view.dart`.

| Element | Decision | Notes |
|---|---|---|
| Scope | Static UI only | Fields mirror `patients` table from s1.1 schema; submit navigates to Home (mock). |
| Layout | `AppFormLayout`, scrollable single column | Same max-width constraint as login. |
| Fields | First name, last name, date of birth, sex (dropdown), CKD stage (dropdown), height (cm, optional), email, password | Required fields validated on submit. |

### 3.4 Caretaker Signup

Implemented at `app/lib/ui/features/onboarding/views/caretaker_signup_view.dart`.

| Element | Decision | Notes |
|---|---|---|
| Scope | Static UI only | Patient linking deferred; submit navigates to Home (mock). |
| Fields | Full name, email, password, patient invite code (optional) | Invite code is a UI placeholder for a later linking flow. |

### 3.5 Home Screen

Implemented at `app/lib/ui/features/home/views/home_view.dart`.

| Element | Decision | Notes |
|---|---|---|
| Scope | Static UI with mock vitals data | Pull-to-refresh reloads latest readings from in-memory repository. |
| Layout | App bar with sign-out action, headline, three vital summary cards, "View all vitals" secondary button | Summary cards reuse `AppOptionCard`; latest value shown as card description. |
| Navigation | Tap card → vital detail page; "View all vitals" → vitals hub; sign out → login | Returning from a vital page refreshes home summaries. |

### 3.6 Vitals Hub

Implemented at `app/lib/ui/features/vitals/views/vitals_hub_view.dart`.

| Element | Decision | Notes |
|---|---|---|
| Scope | Navigation only | Lists all three vital types with short descriptions. |
| Layout | Same option-card pattern as onboarding/home | Icons: blood pressure, glucose, weight. |

### 3.7 Vital Detail Pages (Blood Pressure, Glucose, Weight)

Implemented at:
- `app/lib/ui/features/vitals/views/blood_pressure_view.dart`
- `app/lib/ui/features/vitals/views/blood_glucose_view.dart`
- `app/lib/ui/features/vitals/views/weight_view.dart`

| Element | Decision | Notes |
|---|---|---|
| Scope | Static UI with in-memory mock data | New readings persist for the session only (no Supabase/local DB yet). |
| Layout | App bar + FAB + list of `AppReadingCard` items, or `AppEmptyState` | List separated by `spacingSm`. |
| Add reading | Bottom sheet form opened by FAB | BP: systolic/diastolic and/or heart rate (at least one required). Glucose: mg/dL + optional context. Weight: kg. All support optional notes. |
| Units | BP in mmHg/bpm, glucose in mg/dL, weight in kg | Matches s1.1 schema canonical units. |

## 4. Open Questions

- Full color palette (primary/secondary/accent; only `error` red decided so far) — not yet decided.
- Typography system (font family, full scale, weights) — only `headlineMedium`/`titleMedium`/`bodyMedium`/`optionCardTitle` decided so far.
- Dark mode — explicitly out of scope for now; revisit later.
- Accessibility targets (contrast ratios, text scaling, screen reader support) — important given the patient audience; not yet discussed.
- Real branding/logo assets — login screen currently uses a placeholder Material icon.
- Real auth wiring (Supabase email/password) for login and signup — currently static/sample only.
- Caretaker–patient linking flow — UI placeholder only on caretaker signup.

## 5. Change Log

- **2026-07-03**: Restructured design.md into a living-document format (maintenance instructions, global foundations, page-specific section, change log). Carried over existing decisions as-is: white background, black/mono font color, no animations.
- **2026-07-03**: Built sample Login Screen (static UI, email+password). Introduced first concrete Global Foundations: mono color palette + functional `error` red, spacing scale, headline/body type overrides, button/input component styles, and app-wide disabled route-transition animations (operationalizes the existing "no animations" principle). See Section 2 and Section 3.1.
- **2026-07-04**: Migrated implementation path from `flutter_app/` to `app/`. Added onboarding, signup, home, vitals hub, and vital detail screens. Extended Global Foundations with `titleMedium`, `optionCardTitle`, shared components (`AppOptionCard`, `AppReadingCard`, `AppScreenAppBar`, `AppEmptyState`), secondary/outlined button styles, app bar/FAB/snackbar themes, and bottom-sheet radius. Documented all new pages in Section 3.2–3.7.
