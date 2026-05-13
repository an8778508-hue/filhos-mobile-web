# Design Spec

UI/UX conventions and design tokens. The codebase already drives most tokens from a remote Firestore config (`ConfigCubit.styling`); this spec captures the defaults and the patterns Claude should follow when adding screens.

## 1. Identity

- **Brand:** Criarte — warm, school-friendly, child-centric.
- **Primary color:** `#FF9C00` (orange) — see [lib/core/config/styling.dart](../lib/core/config/styling.dart) `DefaultColors.primary`.
- **Tone:** Encouraging, Portuguese-first, accessible to non-tech-savvy parents.

## 2. Design tokens (defaults, overridable via Firestore)

Source: [lib/core/config/styling.dart](../lib/core/config/styling.dart) `DefaultColors`. **Never hardcode hex values in features — always read via `context.colors.<token>` (extension in `lib/core/utils/extensions/colors_ext.dart`).**

| Role | Default | Use |
|------|---------|-----|
| `primary` | `#FF9C00` | CTAs, active states, brand accents |
| `primaryDark` | `#FF9C00` | Pressed/hover (currently same as primary) |
| `primaryLight` | `#FFE8C4` | Primary surfaces, chips |
| `primaryBackground` | `#FFF5E5` | Section backgrounds |
| `selectedButtonColor` | `#FFF5E5` | Selected toggle/segment |
| `secondary` / `secondaryVariant` | `#FF9C00` | Currently mirrors primary |
| `accent` | `#FFC501` | Highlights, badges |
| `accentLight` | `#FFF5D2` | Accent surfaces |
| `accentDark` | `#D39401` | Accent pressed |
| `background` | `#FFFFFF` | Card surfaces |
| `scaffold` | `#F8F8F8` | Default screen background |
| `secondaryScaffold` | `#F5F5F5` | Nested scaffold areas |
| `lightBackground` | `#FFF5E5` | Soft surfaces |
| `inputBackground` | `#F9F9F9` | Form fields |
| `divider` | `#8F8F8F` | Hairlines |
| `disabled` | `#DFE2E6` | Disabled controls |
| `textColor` | `#000000` | Primary text |
| `secondaryTextColor` | `#FFFFFF` | Text on primary surfaces |
| `labelColor` | `#6B6B6B` | Form labels, captions |
| `warmGray` | `#949494` | Muted body text |
| `greyLight` / `greyLighter` / `greyDark` / `greyDarker` | `#A2A6B2` / `#F2F4F6` / `#828282` / `#6E7482` | Hierarchy in greys |
| `secondaryGrey` | `#E8E8E8` | Subtle dividers/fills |
| `error` | `#E35462` | Errors, destructive actions |
| `errorLighter` | `#FFDBDB` | Error surfaces |
| `alert` | `#FF9C00` | Alert banners (note: same as primary) |
| `success` / `successLight` / `successLighter` | `#42A648` / `#53D468` / `#E5F9D4` | Confirmations |

> **Heads-up:** `primaryDark`, `secondary`, `secondaryVariant`, and `alert` all default to the same orange. If you need real visual differentiation, propose an explicit token rather than reusing `primary` everywhere.

## 3. Typography

Fonts shipped in [assets/fonts/](../assets/fonts/) and declared in [pubspec.yaml](../pubspec.yaml):

| Family | Use | Weights |
|--------|-----|---------|
| **Gotham** | Latin-script UI text (Portuguese, English) | 100 → 900 + italics |
| **Ping** | Arabic UI text | 100 → 900 |
| **Gabarito** | Display / brand accents | 400 → 900 |

`google_fonts` is a dependency but local Gotham/Ping/Gabarito should be preferred for offline reliability.

Typography rules:
- Use `flutter_screenutil` `.sp` for font sizes (design size 430×932).
- Respect `Directionality` — RTL must be tested for Arabic.
- Don't ship raw `TextStyle` literals in features; reuse styles from `lib/core/theme/` or `lib/core/components/`.

## 4. Layout & spacing

- Design size: **430 × 932** (iPhone 14 Pro Max class) via `ScreenUtilInit` in [lib/my_app.dart:50](../lib/my_app.dart#L50).
- Use `.w`, `.h`, `.r`, `.sp` from `flutter_screenutil` rather than literal px.
- Default screen background is `scaffold` (`#F8F8F8`); card content sits on `background` (`#FFFFFF`) with subtle shadow or `divider`.
- 8-px spacing grid is implicit across components — keep paddings on multiples of 4/8 where possible.

## 5. Components

Reusable widgets live in [lib/core/components/](../lib/core/components/) — buttons, text fields, dialogs, snackbars, loading indicators, reactions, image/video tiles. **Before building a one-off widget, check here.**

Notable components and conventions:
- Bottom navigation: `bottom_navy_bar` package, wrapped via the `main` feature.
- Bottom sheets for image/file picking live in [lib/core/attachment_selection/](../lib/core/attachment_selection/).
- Calendar UI: `table_calendar`.
- Forms: built dynamically from [lib/features/add_form/](../lib/features/add_form/) schemas; styled fields delegate to shared field components.
- Loading: spinner via `flutter_spinkit`; long ops should always show progress.

## 6. Navigation

- Single `MaterialApp` with `navigatorKey` ([lib/my_app.dart:30](../lib/my_app.dart#L30)).
- Named-route tracking via `NavObs` in `my_app.dart`.
- Tab shell is `lib/features/main/` (`MainBloc`).
- Approval gate intercepts at `lib/features/your_account_under_review/`.

## 7. Localization in UI

- All strings via `LocalizationKeys` (`lib/core/localization/localization_keys.dart`) + `assets/langs/{en,pt,ar}.json`.
- pt is canonical; en/ar must stay in sync.
- Test RTL flipping for Arabic on every new screen.
- `intl` formatting for dates/numbers; Brazilian-specific formatting via `brasil_fields` (CPF, phone).

## 8. Accessibility (current gaps)

- No explicit semantics labels on most icon-only buttons — flagged as a gap.
- Color-only signaling (alert/primary share the same orange) impedes color-blind users.
- Tap targets generally meet 44pt but should be audited.

## 9. Flavor differences

Visual differences between parents and teachers are minor — same palette, same components. The split is in **information density and verbs**: teachers post, parents read; teachers search children, parents search teachers. When designing, ask "what's the role-appropriate verb?" before adding screen-level branching.

---

## Tasks

### Design tokens
- [ ] [both] Define distinct values for `primaryDark`, `secondary`, `secondaryVariant`, and `alert` — they all currently equal `primary`. Propose new hex values and update `DefaultColors`.
- [ ] [both] Audit feature code for hardcoded hex strings (`Color(0xff...)`) and migrate to `context.colors.<token>`.
- [ ] [both] Document the Firestore-config schema for `styling` in [system.md](system.md) so remote overrides are predictable.

### Typography
- [ ] [both] Define a typography scale (display / title / body / label sizes & weights) and expose as named getters in `lib/core/theme/`.
- [ ] [both] Decide which font is canonical for Portuguese UI (Gotham vs. Gabarito) and remove the unused one if redundant.
- [ ] [both] Verify Arabic-language screens use Ping (not Gotham) via `Directionality` / `localeResolutionCallback`.

### Components
- [ ] [both] Inventory `lib/core/components/` and add a one-line doc comment per component describing intended use.
- [ ] [both] Add a component gallery / catalog screen (debug-only entry) so designers and reviewers can compare instances.
- [ ] [both] Replace any feature-local "Button"/"TextField" duplicates with shared components.

### Navigation
- [ ] [both] Consolidate ad-hoc `Navigator.push` calls into a typed router helper to make the approval-gate audit feasible.
- [ ] [both] Confirm `NavObs` route names cover every screen for analytics / debugging.

### Accessibility
- [ ] [both] Add `Semantics` labels to all icon-only IconButton instances in shared components.
- [ ] [both] Verify minimum 44×44 tap target on every interactive surface.
- [ ] [both] Run a color-contrast audit (WCAG AA) against the default palette; introduce darker/lighter tokens where contrast fails.
- [ ] [both] Test RTL layout on every screen in the Arabic locale build.

### Visual QA
- [ ] [both] Build a Figma (or equivalent) source of truth referenced from here; document Figma file URL when ready.
- [ ] [both] Add golden tests for shared components (buttons, fields, dialogs) once a testing baseline exists.
- [ ] [parents] / [professores] Capture before/after screenshots for any visual PR in both flavors.

### Brand consistency
- [ ] [parents] Confirm launcher icon, splash, and store assets all read "Criarte".
- [ ] [professores] Confirm launcher icon, splash, and store assets all read "ProfeCriarte" (or chosen teacher brand).
