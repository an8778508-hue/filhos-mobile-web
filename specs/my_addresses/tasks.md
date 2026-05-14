---
status: migrated
feature: my_addresses
migrated_from: specs/features.md#my_addresses--p
migrated_date: 2026-05-14
---

# Tasks: My Addresses

**Input**: [spec.md](spec.md), [plan.md](plan.md), and the existing per-feature inventory in [../features.md#my_addresses--p](../features.md#my_addresses--p).

## Migration summary

`my_addresses` ships and lists the user's saved addresses. Add and Edit are wired to `add_address`. Delete is half-wired (dialog stub, button commented out, no backend endpoint). Set-default and swipe-undo are not implemented.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Parallelizable.
- **[Story]**: US1 = list, US2 = add, US3 = edit, US4 = delete, US5 = set-default.

---

## Phase 1: Setup — built (with drift)

- [x] **T-001** Feature folder under [lib/features/my_addresses/](../../lib/features/my_addresses/).
- [x] **T-002** `MyAddressesRepo` singleton + `MyAddressesBloc` factory registered in [init_dependencies.dart:68, 96-98](../../lib/init_dependencies.dart#L68). *(Drift: no feature-root DI class — see T-fix-DI.)*
- [x] **T-003** Localization keys for all visible strings present.

## Phase 2: Foundational — built

- [x] **T-010** `AddressModel` with `fromJson` ([address_model.dart](../../lib/features/my_addresses/models/address_model.dart)).
- [x] **T-011** `MyAddressesRepo.getAddresses` via `NetworkClient.handleRequest`.
- [x] **T-012** Composite `AddressesState{ data, loading, error }` with `fetching/success/failed` helpers.

## Phase 3: User Story 1 — List — built (with gaps)

- [x] **T-020** [US1] Screen mounts → bloc → `FetchAddresses` ([my_addresses_screen.dart:54](../../lib/features/my_addresses/my_addresses_screen.dart#L54)).
- [x] **T-021** [US1] `Loading` while `state.loading`; `EmptyAddress` when `data.isEmpty`.
- [x] **T-022** [US1] `AddressItem` renders every relevant field with Brazil-vs-non-Brazil label switching.
- [x] **T-023** [US1] Pull-to-refresh via `RefreshIndicator` re-dispatches `FetchAddresses`.
- [ ] **T-fix-1** **Surface fetch failures** — today `failed(message)` is silent because the screen branches on `data.isEmpty`. Render an `ErrorScreen` or banner when `state.error != null`.

## Phase 4: User Story 2 — Add — partial

- [x] **T-030** [US2] Empty-state CTA → `AddAddressScreen()` → re-fetch on `pop(true)`.
- [ ] **T-fix-2** **Add an app-bar `+` action for the populated-list view.** Currently commented out at [my_addresses_screen.dart:43-51](../../lib/features/my_addresses/my_addresses_screen.dart#L43-L51). Without it, a user with ≥1 address cannot add a second one from this screen.

## Phase 5: User Story 3 — Edit — built

- [x] **T-040** [US3] Row "Edit" → `AddAddressScreen(addressModel: address)` → re-fetch on `pop(true)`.

## Phase 6: User Story 4 — Delete — wired but dead

- [ ] **T-fix-3** **Implement delete.**
  - Restore the `delete` button in [address_item.dart:201-214](../../lib/features/my_addresses/widgets/address_item.dart#L201-L214).
  - Replace the `//todo` at [my_addresses_screen.dart:110](../../lib/features/my_addresses/my_addresses_screen.dart#L110) with a `DeleteAddress(addressId)` event.
  - Add `Future<Either<Failure, void>> deleteAddress(String id)` to `MyAddressesRepo`, hitting `DELETE regions/addresses/<id>` (or whatever the backend exposes — coordinate).
  - Render success / failure feedback.
- [ ] **T-fix-4** *(features.md)* **Swipe-to-delete with undo.** Wrap each row in `Dismissible`; on dismiss, optimistically remove + show a SnackBar with an "undo" action and a debounce timer before the server `DELETE` fires.

## Phase 7: User Story 5 — Set as default — not implemented

- [ ] **T-fix-5** *(features.md)* **"Set as default" action.**
  - Add `bool isDefault` to `AddressModel.fromJson`.
  - Add a `SetDefaultAddress(addressId)` event and a repo method (endpoint TBD — likely `POST regions/addresses/<id>/default`).
  - Render a "default" badge on the corresponding `AddressItem`.
  - Enforce single-default invariant on the bloc side (mark others false locally).

---

## Phase 8: Cleanups & drift fixes

### Constitution drift fixes
- [ ] **T-fix-DI** Create [lib/features/my_addresses/my_addresses_di.dart](../../lib/features/my_addresses/my_addresses_di.dart) implementing `DependencyInjection`. Move the repo + bloc registrations out of `init_dependencies.dart`.
- [ ] **T-fix-LAYOUT** Move [my_addresses_screen.dart](../../lib/features/my_addresses/my_addresses_screen.dart) into `presentation/`.
- [ ] **T-fix-FLAVOR** Same as the [add_address T-fix-FLAVOR](../add_address/tasks.md#constitution-drift-fixes) — gate the `my_addresses` settings entry on `if (context.isParents)`.

### Code hygiene
- [ ] **T-cleanup-1** Delete `SubmitMyAddressesEvent` ([my_addresses_events.dart:12-13](../../lib/features/my_addresses/bloc/my_addresses_events.dart#L12-L13)) and its empty handler ([my_addresses_bloc.dart:19-22](../../lib/features/my_addresses/bloc/my_addresses_bloc.dart#L19-L22)).
- [ ] **T-cleanup-2** Delete `AddressesState.select(AreaModel)` no-op ([my_addresses_states.dart:44-46](../../lib/features/my_addresses/bloc/my_addresses_states.dart#L44-L46)). Drop the `AreaModel` import.
- [ ] **T-cleanup-3** Delete `initialCity` / `initialRegion` fields on `MyAddressesBloc` ([my_addresses_bloc.dart:11-12](../../lib/features/my_addresses/bloc/my_addresses_bloc.dart#L11-L12)) — never read.
- [ ] **T-cleanup-4** Rename `eventForUserEndpoint` → `addressesEndpoint` in [my_addresses_repo.dart:10](../../lib/features/my_addresses/repo/my_addresses_repo.dart#L10).
- [ ] **T-cleanup-5** Remove debug `print('1111…')` / `print('2222…')` in the empty-state add-flow ([my_addresses_screen.dart:67, 70](../../lib/features/my_addresses/my_addresses_screen.dart#L67-L70)).
- [ ] **T-cleanup-6** Replace hardcoded asset paths in `AddressItem` and `EmptyAddress` (`'assets/icons/map.svg'`, `'assets/icons/edit_thin.svg'`, `'assets/icons/trash.svg'`) with `Assets.icons.*.path` accessors from [shared/assets/assets.gen.dart](../../lib/shared/assets/assets.gen.dart).
- [ ] **T-cleanup-7** The `AddressModel.fromJson` field swap (JSON `state_model` → Dart `cityModel`, JSON `city_model` → Dart `regionModel`) is intentional. Document this with a one-line comment so future readers do not "fix" it.

### Tests (aspirational)
- [ ] **T-test-1** [P] [US1] Bloc test: `FetchAddresses` success / failure / empty mapping.
- [ ] **T-test-2** [P] [US1] Widget test: empty-state CTA pushes `AddAddressScreen` and refetches on `true`.
- [ ] **T-test-3** [P] [US3] Widget test: edit-button push round-trip.

---

## Constitution Drift Fixes summary

- No feature DI class (T-fix-DI).
- Screen at feature root (T-fix-LAYOUT).
- Flavor entry-point not gated (T-fix-FLAVOR).
- Dead `SubmitMyAddressesEvent` / `select(AreaModel)` / `initialCity` / `initialRegion` (T-cleanup-1/2/3).
- Endpoint field misnamed (T-cleanup-4).
- Debug prints (T-cleanup-5).
- Hardcoded asset paths (T-cleanup-6).

## Gaps Found

1. **Delete is wired but dead** — button commented out, `confirmDialog` invokes a `//todo`, no backend endpoint, no repo method.
2. **No "+" action** for adding when the list is non-empty — only the empty state surfaces an add CTA.
3. **No set-default** affordance, model field, event, or endpoint.
4. **Failed fetch is silent** — shows empty state instead of an error UI.
5. **No swipe-to-delete with undo** despite features.md asking for it.
6. **Flavor honesty** — entry-point not gated by `context.isParents`.
