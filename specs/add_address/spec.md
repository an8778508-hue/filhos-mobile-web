---
status: migrated
feature: add_address
flavor_scope: parents
migrated_from: specs/features.md#add_address--p
migrated_date: 2026-05-14
---

# Feature Specification: Add / Edit Address

**Feature Branch**: `(existing — pre-spec-kit)`

**Created**: 2026-05-14 (reverse-engineered)

**Status**: Migrated

**Input**: Reverse-engineered from [lib/features/add_address/](../../lib/features/add_address/) and the existing [features.md `## add_address · P`](../features.md#add_address--p) entry.

## Flavor Scope *(mandatory for Criarte)*

- **Target flavor(s)**: parents (per features.md `· P`).
- **Flavor-conditional behavior**: None inside the feature itself. The screen makes no `context.isParents` / `context.isProfessors` checks. The flavor gate lives at the **call site**: addresses are reached from `my_addresses` (see [my_addresses spec](../my_addresses/spec.md)).
  - Note: today the entry-point `SettingsItem` for `my_addresses` is **not** wrapped in `if (context.isParents)` ([settings_screen.dart:96-107](../../lib/features/settings/settings_screen.dart#L96-L107)), so the screen is technically reachable from both flavors. Treat the feature as parents-focused per features.md and flag the flavor-honesty gap.
- **Server role implication**: None — the endpoint `POST regions/addresses` is the same regardless of role; the user's token determines ownership.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Add a new address (Brazil, CEP-driven) (Priority: P1) 🎯 MVP

A parent opens `AddAddressScreen` from `my_addresses`, picks Brazil as country, types a CEP, the form autofills street / district / city / state from the CEP lookup, then they fill the name / complement and save.

**Why this priority**: This is the dominant happy path for Brazilian users — the bundled `search_cep` package's whole point.

**Independent Test**:
1. Push `AddAddressScreen()` (no `addressModel`).
2. Pick "Brasil" from the country selector.
3. Type a valid 8-digit CEP and submit the inline CEP field.
4. Verify `addressController`, `areaController`, `cityController`, `brazilStatesModel` are populated from `PostmonSearchCep.searchInfoByCep` output.
5. Fill `Name` + (optional) `Complete address`.
6. Tap save.
7. Verify `POST regions/addresses` is dispatched with `address: [{name, country_id, country, city, brazil_state_code, area, address, zip_code, complete_address}]` and a success SnackBar shows, then the screen pops `true`.

**Acceptance Scenarios**:

1. **Given** Brazil is selected, **When** the user submits a valid CEP, **Then** `PostmonSearchCep.searchInfoByCep(cep: value)` is called and on success populates `addressController/areaController/cityController/brazilStatesModel` ([add_address_screen.dart:393-415](../../lib/features/add_address/add_address_screen.dart#L393-L415)).
2. **Given** the CEP lookup fails (Postmon returns `Left`), **When** the await resolves, **Then** `errorCep.value = l.errorMessage` and an `ErrorField` is rendered under the CEP row ([add_address_screen.dart:420-431](../../lib/features/add_address/add_address_screen.dart#L420-L431)).
3. **Given** Brazil is selected and the form validates, **When** the user taps "Save", **Then** `SubmitAddAddressEvent` is dispatched with `region_id == null`, `city_id == null` (Brazil path), and `brazil_state_code` set from the state picker ([add_address_screen.dart:604-620](../../lib/features/add_address/add_address_screen.dart#L604-L620)).
4. **Given** the server returns success, **When** `submitAddressState.success == true`, **Then** a success SnackBar with `address_added_successfully` is shown and `Navigator.pop(true)` is called ([add_address_screen.dart:116-130](../../lib/features/add_address/add_address_screen.dart#L116-L130)).

---

### User Story 2 - Add a new address (non-Brazil, country → city → region cascade) (Priority: P1)

A parent picks a non-Brazil country; the form switches to a three-step cascade — fetch cities for the country, then regions for the city — and the CEP / state / area / city-text-field block is hidden.

**Why this priority**: Same flow priority; just the other half of country selection.

**Independent Test**:
1. Push `AddAddressScreen()`.
2. Pick a non-Brazil country.
3. Wait for `CitiesState.data` to populate.
4. Pick a city → wait for `RegionsState.data` to populate.
5. Pick a region.
6. Fill `Name` + `Address`.
7. Tap save.
8. Verify the request body sends `city_id` (mapped to `"state"` in the JSON body — see [Edge Cases](#edge-cases)) and `region_id` (mapped to `"city"`).

**Acceptance Scenarios**:

1. **Given** a non-Brazil country is chosen, **When** the country is selected, **Then** `SelectCountry` is dispatched → bloc fetches cities via `GET regions/states?city_id=<country.id>` ([add_address_repo.dart:17, 74-84](../../lib/features/add_address/repo/add_address_repo.dart#L17)).
2. **Given** a city is chosen, **When** `SelectCity` fires, **Then** the bloc fetches regions via `GET regions/cities?state_id=<city.id>` ([add_address_repo.dart:19, 86-96](../../lib/features/add_address/repo/add_address_repo.dart#L19)).
3. **Given** a region is chosen and the form validates, **When** the user taps "Save", **Then** `SubmitAddAddressEvent` is dispatched with `region_id` / `city_id` set and `brazil_state_code` null.

---

### User Story 3 - Edit an existing address (Priority: P2)

A parent taps "Edit" on a saved address in `my_addresses`; `AddAddressScreen(addressModel: ...)` opens pre-populated.

**Why this priority**: Round-trip editing is essential UX but adds only initial-state hydration on top of US1/US2.

**Acceptance Scenarios**:

1. **Given** an `addressModel` is passed, **When** the screen mounts, **Then** every controller is initialized from the model (`name`, `address`, `complement`, `zip_code` with `CepInputFormatter`, `cityModel`, `regionModel`, `brazil_state_code`) and the country bloc fetches countries then re-dispatches `SelectCountry(addressModel.countryModel!)` so the dependent dropdowns rehydrate ([add_address_bloc.dart:43-60](../../lib/features/add_address/bloc/add_address_bloc.dart#L43-L60), [add_address_screen.dart:66-83](../../lib/features/add_address/add_address_screen.dart#L66-L83)).
2. **Given** the saved address is Brazilian, **When** the screen mounts, **Then** the matched `BrazilStatesModel` is read from the static `BrazilStates.states` list via `safeFirstWhere` and assigned to `brazilStatesModel`.
3. **Given** the user saves changes, **When** success returns, **Then** the SnackBar reads `address_updated_successfully` (not `address_added_successfully`).

---

### Edge Cases

- **CEP validation before lookup**: features.md asks for it; not implemented. The screen calls `PostmonSearchCep.searchInfoByCep(cep: value)` with whatever was in the input formatter. Invalid CEPs round-trip through the lookup and surface as an error from the service.
- **CEP cache**: features.md asks for it; not implemented. Every lookup hits the network.
- **JSON body key swap**: in [add_address_repo.dart:45, 48](../../lib/features/add_address/repo/add_address_repo.dart#L45-L48) the field names are intentionally swapped — the *Dart* arg `city_id` is sent as JSON `"state"`, and Dart `region_id` is sent as JSON `"city"`. **This matches the backend's nomenclature** (Brazilian "state" / "city") even though the Dart names use the older internal nomenclature ("city" / "region"). Confusing; preserved as-is for backend compatibility.
- **Repeated `city` key in the JSON**: when both `city` and `region_id` are set, the latter overwrites the former in the request body. Dart's map-literal `if` blocks at [add_address_repo.dart:46, 48](../../lib/features/add_address/repo/add_address_repo.dart#L46-L48) both produce `"city"` keys.
- **Snake-case Dart field names**: `country_id`, `city_id`, `region_id`, `brazil_state_code`, `zip_code` violate Dart style. Constitution drift; preserved here for code-honesty.
- **`Print` statements left in screen**: multiple `print(...)` calls around the CEP lookup ([add_address_screen.dart:394, 397, 402, 406-413](../../lib/features/add_address/add_address_screen.dart#L394)).
- **Submission errors**: server failures are surfaced both as a SnackBar (via the error listener) and as an inline `ErrorField` under the save button. Two-channel error UX may double up.
- **Loading overlay**: `loadingCep || countriesState.loading || citiesState.loading || regionsState.loading || submitAddressState.loading` drives a single `LoadingOverlay`. Multiple concurrent loads collapse to one spinner.
- **The form validates `state.regionsState.selected` only when `validList(state.regionsState.data)`** — if the server returned an empty regions list, the user can save without picking one ([add_address_screen.dart:364-368](../../lib/features/add_address/add_address_screen.dart#L364-L368)).
- **No "delete address" surface**: this feature only adds/updates; deletion is shown as a TODO in [my_addresses_screen.dart:104-112](../../lib/features/my_addresses/my_addresses_screen.dart#L104-L112).
- **`AddressType` enum** is declared at [add_address_screen.dart:34](../../lib/features/add_address/add_address_screen.dart#L34) but never used — the relevant UI block (lines 159-208) is commented out.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST present a form with country selector + (Brazil branch) CEP + state picker, or (non-Brazil branch) city picker → region picker, plus name / address / complement / area fields.
- **FR-002**: System MUST fetch countries from `GET regions/countries` on mount ([add_address_repo.dart:14, 62-72](../../lib/features/add_address/repo/add_address_repo.dart#L14)).
- **FR-003**: System MUST fetch dependent dropdowns lazily: cities on `SelectCountry`, regions on `SelectCity`.
- **FR-004**: System MUST integrate with `search_cep` package (`PostmonSearchCep`) when Brazil is selected, autofill street/district/city/state from CEP, and surface lookup errors inline.
- **FR-005**: System MUST send `POST regions/addresses` with a single-element `address: [...]` array containing only present fields (controlled by `if (validString(...))` predicates).
- **FR-006**: System MUST surface success via SnackBar (different copy for add vs edit) and `Navigator.pop(true)`.
- **FR-007**: System MUST display server submission errors both via SnackBar and inline `ErrorField` (current behavior — see Edge Cases for the double-channel concern).
- **FR-008**: System MUST round-trip an `AddressModel` for edit — every relevant field hydrates a controller / value notifier / bloc state on mount.
- **FR-009** (gap from features.md): System SHOULD validate CEP format (8 digits) **before** issuing the lookup to avoid pointless requests.
- **FR-010** (gap from features.md): System SHOULD cache resolved CEPs in `LocalDatabaseRepo` to short-circuit repeat lookups within a session.

### Localization Requirements

| Key | Use site |
|---|---|
| `add_address` | App bar title (add mode) + `EmptyAddress` CTA |
| `edit_address` | App bar title (edit mode) |
| `name` | Name field hint + label |
| `country` | Country selector label |
| `city` | City selector label + Brazil city text field label |
| `region` | Region selector label |
| `cep` | CEP field label |
| `address` | Address field hint + label |
| `complete_address` | Complement field hint + label |
| `area` | Brazil area text field label |
| `state` | Brazil state picker label |
| `save_address` | Save CTA |
| `this_field_cant_be_empty` | Validators |
| `address_added_successfully` | Success SnackBar (add) |
| `address_updated_successfully` | Success SnackBar (edit) |

No new keys required.

### Backend Touchpoints

- **REST endpoints** (base `https://criarte.filhos.app/api/v1/`):
  - `GET regions/countries` — list of countries.
  - `GET regions/states?city_id=<country.id>` — cities for a country. **Note**: the query-param key is `city_id` but the value is a *country* id; preserved for backend compatibility.
  - `GET regions/cities?state_id=<city.id>` — regions for a city. Same nomenclature swap.
  - `POST regions/addresses` — add or update address. Body: `{address: [{...}]}`.
- **Headers**: standard `Authorization` + `school_id` + `lang` via `NetworkInterceptor`.
- **Third-party**: `PostmonSearchCep` from the `search_cep` package — calls a public Postmon endpoint to resolve CEPs.
- **Firebase / Firestore**: not used.

### Permissions & Approval Gate

- Reachable post-login only; approval gate enforced upstream by `my_addresses` / settings shell.
- No device permissions.

### Key Entities

- **`CountryModel`** ([country_model.dart](../../lib/features/add_address/models/country_model.dart)) — `{id, value, name, code, phone_code, emoji_u, emoji_image}`.
- **`CityModel`** ([city_model.dart](../../lib/features/add_address/models/city_model.dart)) — `{id, name, country_id}`.
- **`RegionModel`** ([region_model.dart](../../lib/features/add_address/models/region_model.dart)) — `{id, name, city_id}`.
- **`AreaModel`** ([area_model.dart](../../lib/features/add_address/models/area_model.dart)) — same shape as `CountryModel` but **not referenced from `AddAddressScreen` or the bloc** at runtime. Used only by `my_addresses` state's `select(...)` no-op ([my_addresses/bloc/my_addresses_states.dart:44](../../lib/features/my_addresses/bloc/my_addresses_states.dart#L44)). Effectively dead.
- **`AddAddressStates`** ([add_address_states.dart](../../lib/features/add_address/bloc/add_address_states.dart)) — composite of `CountriesState`, `CitiesState`, `RegionsState`, `SubmitAddressState`.
- **`AddressModel`** (shared with `my_addresses` — [my_addresses/models/address_model.dart](../../lib/features/my_addresses/models/address_model.dart)) — input for edit mode.
- **`BrazilStatesModel`** (from [core/utils/constants/brazil_states.dart](../../lib/core/utils/constants/brazil_states.dart)) — static state list; the screen picks from it for Brazilian addresses.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A new parent can save a Brazilian address in under 60 seconds, with the CEP lookup populating ≥4 fields (street, district, city, state).
- **SC-002**: Editing an existing address pre-populates every previously saved field correctly on mount.
- **SC-003**: Network failures on countries / cities / regions / CEP lookup do not leave the screen in a stuck loading state.
- **SC-004**: With CEP format pre-validation (FR-009), invalid-format inputs do not produce a Postmon request.

## Assumptions

- The `regions/states` / `regions/cities` endpoints exist on the backend with the documented (swapped) param naming and have not been renamed since this feature shipped.
- `PostmonSearchCep` remains a viable provider — `search_cep` package offers multiple providers; switching providers requires a one-line change.
- Brazilian addresses do not need a server-side `region_id` (the form omits it on the Brazil branch).
- The non-Brazil "city" picker really means a sub-country administrative unit and the "region" picker is the next-level-down (city/town). This matches what the JSON body sends (Dart `city_id` → JSON `state`, Dart `region_id` → JSON `city`).
