---
status: migrated
feature: add_address
migrated_from: lib/features/add_address/
migrated_date: 2026-05-14
---

# Implementation Plan: Add / Edit Address

**Branch**: `(existing — pre-spec-kit)` | **Date**: 2026-05-14 (reverse-engineered) | **Spec**: [spec.md](spec.md)

**Input**: [specs/add_address/spec.md](spec.md) and code in [lib/features/add_address/](../../lib/features/add_address/).

## Summary

`add_address` is the parent-facing form for creating or editing an address. It has two branches: a Brazil branch (CEP-driven, with state picker) and a non-Brazil branch (country → city → region cascade). The bloc composes four sub-states (`CountriesState`, `CitiesState`, `RegionsState`, `SubmitAddressState`) into one `AddAddressStates`.

## Technical Context

**Language/Version**: Dart `>=3.0.5 <4.0.0` · Flutter 3.29.3.

**Primary Dependencies**:

- `flutter_bloc` — `AddAddressBloc extends Bloc<AddAddressEvents, AddAddressStates>` with typed `on<Event>` handlers (good — no catch-all here).
- `get_it` — `AddressesRepo` registered as a singleton, `AddAddressBloc` as a factory ([init_dependencies.dart:67, 93-95](../../lib/init_dependencies.dart#L67)). No feature-root DI class.
- `dio` via `NetworkClient.handleRequest` — `Either<Failure, T>` return.
- `search_cep` ≥ 4.0 — `PostmonSearchCep` for CEP lookup.
- `brasil_fields` — `CepInputFormatter` for CEP input formatting in the form.
- `flutter_screenutil` — sizing.

**Storage**: None today. `LocalDatabaseRepo` is **not** wired (would be needed for the CEP cache in FR-010).

**Testing**: None.

**Target Platform**: iOS + Android (Brazilian users); parents flavor.

**Project Type**: Flutter mobile feature, slightly non-standard layout (screen file lives at feature root instead of under `presentation/`).

**Performance Goals**: CEP lookup round-trip ≤ 1.5 s on a warm network (Postmon-bound).

**Constraints**:

- The repo's request body is hand-rolled with conditional inclusion (`if (validString(...)) "key": ...`). Adding a new field is mechanical but error-prone — see the duplicate-`city` key bug.
- The two endpoint paths `regions/states` and `regions/cities` are named after Brazilian admin levels but parametrized with non-Brazilian IDs — confusing but matched to backend nomenclature.

**Scale/Scope**: 9 .dart files, ~870 LOC (most of it the screen).

## Project Structure

### Documentation (this feature)

```text
specs/add_address/
├── spec.md
├── plan.md
└── tasks.md
```

### Source Code (existing)

```text
lib/features/add_address/
├── add_address_screen.dart                  # Entry (not under presentation/)
├── bloc/
│   ├── add_address_bloc.dart                # Typed event handlers
│   ├── add_address_events.dart              # FetchCountries / SelectCountry / SelectCity / SelectRegion / SubmitAddAddressEvent
│   └── add_address_states.dart              # Composite AddAddressStates + 4 sub-states
├── models/
│   ├── country_model.dart
│   ├── city_model.dart
│   ├── region_model.dart
│   └── area_model.dart                      # Defined; runtime-unused (kept for my_addresses placeholder)
└── repo/
    └── add_address_repo.dart                # AddressesRepo (singleton)
```

### Cross-feature touch points

- [lib/features/my_addresses/](../../lib/features/my_addresses/) — pushes `AddAddressScreen(addressModel: address)` for edit, plain `AddAddressScreen()` for add. Awaits `true` to refetch the list.
- [lib/features/my_addresses/models/address_model.dart](../../lib/features/my_addresses/models/address_model.dart) — the input model for edit mode.
- [lib/core/utils/constants/brazil_states.dart](../../lib/core/utils/constants/brazil_states.dart) — static list of Brazilian states for the picker.
- [lib/core/components/items/address/](../../lib/core/components/items/address/) — row widgets (`AddressCountryItem`, `AddressCityItem`, `AddressRegionItem`, `BrazilStateItem`) consumed by the screen's `SelectableField`s.
- [lib/core/components/fromatters/row_formatters.dart](../../lib/core/components/fromatters/row_formatters.dart) — `RowFormatters` widget hosts the CEP field.
- [lib/core/utils/funuctions/global_functions.dart](../../lib/core/utils/funuctions/global_functions.dart) — `isBrazilCountry(code)` predicate used in 8 places in the screen.

## Implementation Phases

This feature was migrated; phases reflect history.

- **Phase 1 — Setup**: feature folder + DI registration in `init_dependencies.dart`. ✓
- **Phase 2 — Foundational**: 4 models + `AddressesRepo` (countries/cities/regions/addOrUpdate). ✓
- **Phase 3 — User Story 1 (Brazil)**: CEP integration + state picker + `isBrazilCountry` branching. ✓
- **Phase 4 — User Story 2 (non-Brazil)**: country → city → region cascade + dependent `SelectableField`s. ✓
- **Phase 5 — User Story 3 (edit)**: `addressModel` constructor + initial-state hydration. ✓
- **Phase 6 — Gaps**: CEP format validation, CEP cache, body-shape cleanup, layout normalization. Pending — see [tasks.md](tasks.md).

## Technical Decisions

| Decision | Rationale | Note |
|---|---|---|
| Composite `AddAddressStates` with four sub-states | Lets `BlocSelector` subscribe to each slice independently without re-rendering the whole form. | Verbose copy-with helpers but readable. |
| Hand-rolled JSON body in `addOrUpdateAddress` | The endpoint accepts an array shape (`address: [{...}]`) — easier to inline than to model. | Duplicate-`city` key bug (see Edge Cases in spec.md); fragile to extend. |
| `search_cep` via `PostmonSearchCep` | Postmon offers a free public CEP API. | Package supports multiple providers — `ViaCepSearchCep`, `WidenetSearchCep` — swap if rate-limited. |
| Hydrate controllers in `initState` from `addressModel` and re-dispatch `SelectCountry` after countries return | Avoids passing an initial country into the bloc; the screen orchestrates rehydration. | Tied to the screen's `Builder` boundaries. |

## Constitution Check

Verified against [.specify/memory/constitution.md](../../.specify/memory/constitution.md):

- [ ] **I. Feature-First Layout** — feature uses `bloc/`, `models/`, `repo/` but the screen file is at the feature root instead of `presentation/`. ⚠️ Minor drift; see tasks.md.
- [ ] **II. Dependency Direction** — no `AddAddressInjection`. `AddressesRepo` and `AddAddressBloc` are registered directly in `init_dependencies.dart`. ⚠️ Same drift as `search_for_filter`; see tasks.md.
- [x] **III. Networking Contract** — `AddressesRepo` uses `NetworkClient.handleRequest` returning `Either<Failure, T>`. ✓
- [x] **IV. Persistence Discipline** — N/A today.
- [ ] **V. Flavor Branching** — feature has no flavor branch but features.md tags it `· P`; the call site in `settings_screen.dart` is **not** gated by `if (context.isParents)`. ⚠️ Flavor-honesty gap surfaced; fix lives in `settings` or `my_addresses`.
- [x] **VI. Localization** — every visible string routes through `LocalizationKeys.*`. ✓
- [x] **VII. Chat Source of Truth** — N/A.
- [x] **VIII. Approval Gate** — reached from settings, post-login.
- [x] **IX. Medicine Reminders** — N/A.
- [ ] **X. Theming & Sizing** — mostly compliant; uses `.h`/`.w`/`.sp`/`.r` and `context.colors.*`. ⚠️ A handful of `Colors.white` and `Colors.grey` literals in the form fields ([add_address_screen.dart:237, 236](../../lib/features/add_address/add_address_screen.dart#L237)).

## Dependencies

- Consumed by `my_addresses` (push + return).
- Shared `AddressModel` lives in `my_addresses` — bi-directional reference (`add_address` imports from `my_addresses` and vice versa).
- Depends on `core/components/items/address/*` for row widgets.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| Screen at feature root | Earlier convention. | Move to `presentation/add_address_screen.dart` to match sibling features. |
| No `AddAddressInjection` | Bloc + repo registered inline. | Add a feature-root DI class. |
| `AreaModel` never instantiated | Reserved for a future "area" picker. | Delete. |
| `AddressType` enum + commented UI block at top of form | Earlier prototype of an address-type segmented control. | Delete the enum and the commented-out UI. |
| `print(...)` calls around CEP lookup | Quick logging. | Replace with the structured logger from [features.md cross-feature task](../features.md#cross-feature-tasks). |
| Hand-rolled body with duplicate `"city"` key when both `city` text and `region_id` are present | Map literal; easy. | Move to a typed request object; eliminate the conditional repetition. |
| Snake-case Dart field names (`country_id`, `zip_code`, …) | Mirror the JSON keys. | Use lowerCamelCase in Dart, map to snake_case at the JSON boundary. |
| Two-channel error UX (SnackBar + inline `ErrorField`) | Defensive coverage. | Pick one. |
| `bloc.add(SelectCountry(r.first))` is commented out at [add_address_bloc.dart:55](../../lib/features/add_address/bloc/add_address_bloc.dart#L55) | Earlier auto-select behavior. | Decide: keep user-driven selection or auto-pick first; remove dead branch. |
