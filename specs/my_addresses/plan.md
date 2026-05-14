---
status: migrated
feature: my_addresses
migrated_from: lib/features/my_addresses/
migrated_date: 2026-05-14
---

# Implementation Plan: My Addresses

**Branch**: `(existing — pre-spec-kit)` | **Date**: 2026-05-14 (reverse-engineered) | **Spec**: [spec.md](spec.md)

**Input**: [specs/my_addresses/spec.md](spec.md) and code in [lib/features/my_addresses/](../../lib/features/my_addresses/).

## Summary

`my_addresses` is the read-side of the address pair (the write-side is [add_address](../add_address/plan.md)). It fetches the user's addresses on mount, renders an `AddressItem` per row, supports pull-to-refresh, and round-trips to `AddAddressScreen` for add/edit. Delete and set-default are flagged but not implemented.

## Technical Context

**Language/Version**: Dart `>=3.0.5 <4.0.0` · Flutter 3.29.3.

**Primary Dependencies**:

- `flutter_bloc` — `MyAddressesBloc extends Bloc<MyAddressesEvents, MyAddressesStates>` with typed `on<FetchAddresses>` handler.
- `get_it` — `MyAddressesRepo` and `MyAddressesBloc` registered in [init_dependencies.dart:68, 96-98](../../lib/init_dependencies.dart#L68). No feature-root DI class.
- `dio` via `NetworkClient.handleRequest`.
- `flutter_svg`, `flutter_screenutil`.

**Storage**: None.

**Testing**: None.

**Target Platform**: iOS + Android, parents flavor (per features.md `· P`).

**Project Type**: Read-only list feature with round-trip to an editor screen.

**Performance Goals**: List render under 1.5 s on a warm network.

**Constraints**:

- The screen takes a hard dependency on `AddAddressScreen` — they share `AddressModel`.
- The shared model lives **in this feature**, not in `add_address` (despite `add_address` being the writer). That is the conventional choice (read-side owns the model) but worth noting.

**Scale/Scope**: 8 .dart files, ~400 LOC.

## Project Structure

### Documentation (this feature)

```text
specs/my_addresses/
├── spec.md
├── plan.md
└── tasks.md
```

### Source Code (existing)

```text
lib/features/my_addresses/
├── my_addresses_screen.dart                # Entry — not under presentation/
├── bloc/
│   ├── my_addresses_bloc.dart              # Typed on<FetchAddresses> handler; on<SubmitMyAddressesEvent> empty
│   ├── my_addresses_events.dart            # FetchAddresses + dead SubmitMyAddressesEvent
│   └── my_addresses_states.dart            # AddressesState { data, loading, error }
├── models/
│   └── address_model.dart                  # Shared with add_address
├── repo/
│   └── my_addresses_repo.dart              # MyAddressesRepo
└── widgets/
    ├── address_item.dart                   # Card renderer
    └── empty_address.dart                  # Empty state with CTA
```

### Cross-feature touch points

- [lib/features/add_address/](../../lib/features/add_address/) — push/pop loop for add/edit.
- [lib/features/add_address/models/{city,region,country}_model.dart](../../lib/features/add_address/models/) — nested models inside `AddressModel`.
- [lib/core/utils/constants/brazil_states.dart](../../lib/core/utils/constants/brazil_states.dart) — for resolving Brazilian state name on `AddressItem`.
- [lib/core/utils/funuctions/global_functions.dart](../../lib/core/utils/funuctions/global_functions.dart) — `isBrazilCountry(code)` predicate.
- [lib/core/components/dialogs/dialogs_functions.dart](../../lib/core/components/dialogs/dialogs_functions.dart) — `confirmDialog` for the (currently dead) delete flow.
- [lib/features/settings/settings_screen.dart:96-107](../../lib/features/settings/settings_screen.dart#L96-L107) — entry point.

## Implementation Phases

- **Phase 1 — Setup**: feature folder + DI. ✓
- **Phase 2 — Foundational**: `MyAddressesRepo` + `AddressesState` composite. ✓
- **Phase 3 — User Story 1 (list)**: screen + `AddressItem` + `EmptyAddress`. ✓
- **Phase 4 — User Story 2/3 (add/edit)**: push/pop to `AddAddressScreen` + refetch on `true`. ✓
- **Phase 5 — User Story 4/5 (delete / set-default)**: not implemented. Pending — see [tasks.md](tasks.md).

## Technical Decisions

| Decision | Rationale | Note |
|---|---|---|
| Round-trip to `AddAddressScreen` returns `true` to trigger refetch | Avoids optimistic state mutation; trivially correct. | A surgical "insert returned address" path would be smoother UX. |
| `AddressModel` owned by this feature (read-side) | Read-side feature surfaces the row type. | `add_address` imports it; bidirectional dependency. |
| `EmptyAddress.onAddNewTapped` callback gating | Avoids embedding navigation in the leaf widget. | Reasonable. |
| Single composite state (`AddressesState` only) | Only one async slice in this feature. | Simple. |

## Constitution Check

- [ ] **I. Feature-First Layout** — screen at feature root (not under `presentation/`). ⚠️
- [ ] **II. Dependency Direction** — no feature-root `MyAddressesInjection` class. ⚠️
- [x] **III. Networking Contract** — uses `NetworkClient.handleRequest`. ✓
- [x] **IV. Persistence Discipline** — N/A.
- [ ] **V. Flavor Branching** — feature has no branch; entry-point not gated by `context.isParents`. ⚠️ (Same call site as `add_address`.)
- [x] **VI. Localization** — every visible string routes through `LocalizationKeys.*`. ✓
- [x] **VII. Chat Source of Truth** — N/A.
- [x] **VIII. Approval Gate** — reached from settings, post-login.
- [x] **IX. Medicine Reminders** — N/A.
- [x] **X. Theming & Sizing** — `.h`/`.w`/`.csh`/`.csw`/`.sp` + `context.colors.*` tokens. ✓

## Dependencies

- Depends on `add_address` for the editor screen.
- Consumed by `settings/settings_screen.dart`.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| Screen at feature root | Earlier convention. | Move to `presentation/`. |
| No feature DI class | Inline registration. | Add `MyAddressesInjection`. |
| `SubmitMyAddressesEvent` handler is empty | Reserved for an unimplemented submit path. | Delete event + empty handler. |
| `AddressesState.select(AreaModel)` no-op | Reserved/placeholder. | Delete. |
| `initialCity` / `initialRegion` fields on `MyAddressesBloc` never read | Carried over from `AddAddressBloc`'s shape. | Delete. |
| `eventForUserEndpoint` field name in repo | Copy-pasted from an "events" template. | Rename to `addressesEndpoint`. |
| Hardcoded `'assets/icons/map.svg'` / `'assets/icons/edit_thin.svg'` / `'assets/icons/trash.svg'` literal paths in widgets | The repo also has the generated `assets.gen.dart` accessors. | Use `Assets.icons.map.path`. |
| Two debug-print lines in empty-state add-flow | Leftover. | Remove. |
| Delete action wired but dead | Backend endpoint missing. | Either ship the delete or remove the dialog wiring. |
