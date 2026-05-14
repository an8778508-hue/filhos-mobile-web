---
status: migrated
feature: add_address
migrated_from: specs/features.md#add_address--p
migrated_date: 2026-05-14
---

# Tasks: Add / Edit Address

**Input**: [spec.md](spec.md), [plan.md](plan.md), and the existing per-feature inventory in [../features.md#add_address--p](../features.md#add_address--p).

## Migration summary

`add_address` ships and is reached from `my_addresses`. Brazil branch uses CEP lookup via `search_cep`; non-Brazil branch uses country → city → region cascade. Two features.md gaps (CEP format pre-validation + CEP cache) plus several hygiene/drift items remain.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Parallelizable.
- **[Story]**: US1 = Brazil add, US2 = non-Brazil add, US3 = edit.

---

## Phase 1: Setup — built (with drift)

- [x] **T-001** Feature folder at [lib/features/add_address/](../../lib/features/add_address/).
- [x] **T-002** `AddressesRepo` registered as singleton + `AddAddressBloc` as factory in [init_dependencies.dart:67, 93-95](../../lib/init_dependencies.dart#L67). *(Drift: no feature-root DI class — see T-fix-DI.)*
- [x] **T-003** Localization keys for all visible strings present in all three langs.

## Phase 2: Foundational — built

- [x] **T-010** `CountryModel`, `CityModel`, `RegionModel` + `AreaModel` (unused).
- [x] **T-011** `AddressesRepo.getCountries / getCities / getRegions / addOrUpdateAddress` via `NetworkClient.handleRequest`.
- [x] **T-012** Composite `AddAddressStates` with four sub-states.
- [x] **T-013** Typed bloc handlers (`on<FetchCountries>`, `on<SelectCountry>`, `on<SelectCity>`, `on<SelectRegion>`, `on<SubmitAddAddressEvent>`).

## Phase 3: User Story 1 — Brazil add — built (with gaps)

- [x] **T-020** [US1] CEP field with `CepInputFormatter` (`brasil_fields`).
- [x] **T-021** [US1] `PostmonSearchCep.searchInfoByCep(cep: value)` on submit; autofill `addressController` / `areaController` / `cityController` / `brazilStatesModel`.
- [x] **T-022** [US1] Inline `ErrorField` for CEP lookup errors via the `errorCep` `ValueNotifier`.
- [x] **T-023** [US1] State picker bound to static `BrazilStates.states`.
- [x] **T-024** [US1] Save dispatches `SubmitAddAddressEvent` with `brazil_state_code` and no `region_id`/`city_id`.

## Phase 4: User Story 2 — Non-Brazil cascade — built

- [x] **T-030** [US2] `SelectCountry` → `getCities(country.id)` → `CitiesState`.
- [x] **T-031** [US2] `SelectCity` → `getRegions(city.id)` → `RegionsState`.
- [x] **T-032** [US2] Conditional rendering: Brazil block hides cascade; non-Brazil block hides CEP/state/area-text.

## Phase 5: User Story 3 — Edit — built

- [x] **T-040** [US3] Constructor `AddAddressScreen({addressModel})` hydrates all controllers in `initState`.
- [x] **T-041** [US3] `FetchCountries(addressModel: ...)` re-dispatches `SelectCountry(addressModel.countryModel)` on response to chain dependent dropdowns.
- [x] **T-042** [US3] Success SnackBar differentiates `address_added_successfully` vs `address_updated_successfully`.

---

## Phase 6: Gaps & cleanups

### From features.md
- [ ] **T-fix-1** *(features.md)* **Validate CEP format before lookup.** Add a regex/length guard (`^\d{5}-?\d{3}$`) on the CEP input before invoking `PostmonSearchCep.searchInfoByCep(...)` in [add_address_screen.dart:393-415](../../lib/features/add_address/add_address_screen.dart#L393-L415). Surface a localized validation message; do not fire the lookup.
- [ ] **T-fix-2** *(features.md)* **Cache last-resolved CEPs** in `LocalDatabaseRepo` (or in-memory map keyed by sanitized CEP). Short-circuit duplicate lookups within a session. Wire `LocalDatabaseRepo` into the bloc.

### Constitution drift fixes
- [ ] **T-fix-DI** Create [lib/features/add_address/add_address_di.dart](../../lib/features/add_address/add_address_di.dart) implementing `DependencyInjection`. Move the `AddressesRepo` singleton and `AddAddressBloc` factory registrations out of `init_dependencies.dart`.
- [ ] **T-fix-LAYOUT** Move [add_address_screen.dart](../../lib/features/add_address/add_address_screen.dart) into `presentation/add_address_screen.dart` to match sibling features.
- [ ] **T-fix-FLAVOR** Wrap the `my_addresses` entry-point `SettingsItem` ([settings_screen.dart:96-107](../../lib/features/settings/settings_screen.dart#L96-L107)) in `if (context.isParents)` so the feature is parents-only as features.md states. (Logically belongs to the `settings` or `my_addresses` task list — recorded here for traceability.)
- [ ] **T-fix-3** Replace `Colors.white` ([add_address_screen.dart:237](../../lib/features/add_address/add_address_screen.dart#L237)) and `Colors.grey` ([line 236](../../lib/features/add_address/add_address_screen.dart#L236)) with `context.colors.*` tokens.
- [ ] **T-fix-4** Replace snake-case Dart field names (`country_id`, `city_id`, `region_id`, `brazil_state_code`, `zip_code`) with `lowerCamelCase`. Map to snake_case only at the JSON boundary.

### Code hygiene
- [ ] **T-cleanup-1** Delete the unused `AreaModel` ([area_model.dart](../../lib/features/add_address/models/area_model.dart)). Also remove the dead `select(AreaModel)` no-op on `AddressesState` in [my_addresses/bloc/my_addresses_states.dart:44](../../lib/features/my_addresses/bloc/my_addresses_states.dart#L44).
- [ ] **T-cleanup-2** Delete the `AddressType` enum ([add_address_screen.dart:34](../../lib/features/add_address/add_address_screen.dart#L34)) and the commented-out UI block ([lines 159-208](../../lib/features/add_address/add_address_screen.dart#L159-L208)).
- [ ] **T-cleanup-3** Replace `print(...)` debug calls around the CEP lookup ([add_address_screen.dart:394, 397, 402, 406-413](../../lib/features/add_address/add_address_screen.dart#L394)) with a structured logger or remove.
- [ ] **T-cleanup-4** Fix the duplicate-`"city"` key in `addOrUpdateAddress` body ([add_address_repo.dart:46, 48](../../lib/features/add_address/repo/add_address_repo.dart#L46-L48)). Decide on the canonical mapping (Dart `city` text vs Dart `region_id`) — currently `region_id` silently overwrites `city`.
- [ ] **T-cleanup-5** Pick ONE error-surface channel — drop either the SnackBar listener at [add_address_screen.dart:107-115](../../lib/features/add_address/add_address_screen.dart#L107-L115) **or** the inline `ErrorField` at [lines 633-640](../../lib/features/add_address/add_address_screen.dart#L633-L640). Keep both only if the UX team explicitly wants doubled feedback.
- [ ] **T-cleanup-6** Either restore or delete the commented `bloc.add(SelectCountry(r.first))` auto-select line at [add_address_bloc.dart:55](../../lib/features/add_address/bloc/add_address_bloc.dart#L55) (also at [line 75](../../lib/features/add_address/bloc/add_address_bloc.dart#L75) and [line 94](../../lib/features/add_address/bloc/add_address_bloc.dart#L94)).
- [ ] **T-cleanup-7** Decide whether to keep the dead `Region` validator at [add_address_screen.dart:364-368](../../lib/features/add_address/add_address_screen.dart#L364-L368) that only fires when `validList(state.data)` — currently a user can save without picking a region if the server returned an empty list.

### Tests (aspirational)
- [ ] **T-test-1** [P] [US1] Widget test: pick Brazil, submit CEP, assert autofill.
- [ ] **T-test-2** [P] [US2] Widget test: pick non-Brazil country → city → region, assert request payload contains `region_id`/`city_id` but no `brazil_state_code`.
- [ ] **T-test-3** [P] [US3] Widget test: passing an `addressModel` hydrates controllers and re-fires `SelectCountry`.
- [ ] **T-test-4** [P] Repo test: `addOrUpdateAddress` body shape with various optional-field combinations.

---

## Constitution Drift Fixes summary

- No feature-root DI class (T-fix-DI).
- Screen file at feature root, not under `presentation/` (T-fix-LAYOUT).
- Flavor honesty: entry-point not gated by `context.isParents` (T-fix-FLAVOR).
- `Colors.white` / `Colors.grey` literals (T-fix-3).
- Snake-case Dart names (T-fix-4).
- `print(...)` calls (T-cleanup-3).
- Duplicate `"city"` JSON key (T-cleanup-4).
- Dead `AreaModel`, `AddressType` enum, commented UI/auto-select (T-cleanup-1, T-cleanup-2, T-cleanup-6).

## Gaps Found

1. **CEP format pre-validation missing** — features.md flagged; today every input round-trips through Postmon.
2. **No CEP cache** — every lookup is a network call.
3. **Duplicate `"city"` JSON body key** — `region_id` silently overwrites Brazil's `city` text in the same request body.
4. **Snake-case Dart field names** — repo + events + state all carry `country_id`/`zip_code`-style identifiers.
5. **Flavor honesty drift at the call site** — the `my_addresses` settings entry is unconditionally visible, despite the features.md `· P` tag.
6. **Two-channel submission error UI** — SnackBar + inline ErrorField on the same failure.
7. **`AreaModel` and `AddressType` are dead code.**
8. **No delete-address surface** anywhere yet.
