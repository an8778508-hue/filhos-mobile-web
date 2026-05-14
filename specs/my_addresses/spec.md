---
status: migrated
feature: my_addresses
flavor_scope: parents
migrated_from: specs/features.md#my_addresses--p
migrated_date: 2026-05-14
---

# Feature Specification: My Addresses

**Feature Branch**: `(existing — pre-spec-kit)`

**Created**: 2026-05-14 (reverse-engineered)

**Status**: Migrated

**Input**: Reverse-engineered from [lib/features/my_addresses/](../../lib/features/my_addresses/) and the existing [features.md `## my_addresses · P`](../features.md#my_addresses--p) entry.

## Flavor Scope *(mandatory for Criarte)*

- **Target flavor(s)**: parents (per features.md `· P`).
- **Flavor-conditional behavior**: None inside the feature.
- **Flavor-honesty gap**: the settings entry-point for `my_addresses` is **not** wrapped in `if (context.isParents)` ([settings_screen.dart:96-107](../../lib/features/settings/settings_screen.dart#L96-L107)). The screen is reachable from both flavors today. Track the fix in [add_address tasks T-fix-FLAVOR](../add_address/tasks.md#constitution-drift-fixes) — same call site.
- **Server role implication**: None — `GET regions/addresses` returns the caller's addresses regardless of role.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - List saved addresses (Priority: P1) 🎯 MVP

A parent opens "My Addresses" from settings; the screen fetches their saved addresses and renders them as cards.

**Why this priority**: Without the list, the rest of the feature is meaningless.

**Independent Test**:
1. From settings, tap "My Addresses".
2. Verify the bloc dispatches `FetchAddresses` on mount.
3. Verify `GET regions/addresses` is called and the response is parsed into `List<AddressModel>`.
4. Verify each address renders as an `AddressItem` card.

**Acceptance Scenarios**:

1. **Given** the user opens the screen, **When** `MyAddressesBloc` is constructed, **Then** `FetchAddresses()` is added ([my_addresses_screen.dart:54](../../lib/features/my_addresses/my_addresses_screen.dart#L54)).
2. **Given** the request is in flight, **When** `state.addressesState.loading == true`, **Then** a centered `Loading()` is shown ([my_addresses_screen.dart:61-63](../../lib/features/my_addresses/my_addresses_screen.dart#L61-L63)).
3. **Given** the request returns `[]`, **When** the success state lands with empty data, **Then** the `EmptyAddress` widget is shown with an "Add address" CTA ([my_addresses_screen.dart:64-73](../../lib/features/my_addresses/my_addresses_screen.dart#L64-L73)).
4. **Given** the request succeeds with addresses, **When** the list renders, **Then** each item shows name + address + city + area/region + (Brazil only) state + complement + zip + country phone code + country name ([address_item.dart:34-176](../../lib/features/my_addresses/widgets/address_item.dart#L34-L176)).
5. **Given** the user pulls down, **When** `RefreshIndicator.onRefresh` fires, **Then** `FetchAddresses()` re-dispatches and the list re-loads ([my_addresses_screen.dart:80-83](../../lib/features/my_addresses/my_addresses_screen.dart#L80-L83)).
6. **Given** the request fails, **When** `state.addressesState.failed(message)` is emitted, **Then** the screen **shows the empty state** (no error UI). The `error` field on the state is set but not rendered.

---

### User Story 2 - Add a new address (Priority: P1)

From the empty state's CTA or (TODO: a `+` action in the app bar — currently commented out at [my_addresses_screen.dart:43-51](../../lib/features/my_addresses/my_addresses_screen.dart#L43-L51)), the user pushes `AddAddressScreen()`.

**Why this priority**: Required for any user to populate the list.

**Acceptance Scenarios**:

1. **Given** the list is empty, **When** the user taps the empty-state CTA, **Then** `AddAddressScreen()` is pushed; on `Navigator.pop(true)` the bloc re-dispatches `FetchAddresses` ([my_addresses_screen.dart:65-72](../../lib/features/my_addresses/my_addresses_screen.dart#L65-L72)).
2. **Gap**: There is **no `+` action in the populated-list view**. The app-bar action is commented out. Once a list exists, a user must wait for the empty state to add another address (impossible) — currently only the **edit** path is reachable from a populated list. *(Flagged in features.md? Implied. Recorded as gap below.)*

---

### User Story 3 - Edit an address (Priority: P1)

From a list item, the user taps "Edit" to open `AddAddressScreen(addressModel: address)`.

**Acceptance Scenarios**:

1. **Given** the list is showing items, **When** the user taps "Edit" on a row, **Then** `AddAddressScreen(addressModel: address)` is pushed; on `pop(true)` the bloc re-dispatches `FetchAddresses` ([my_addresses_screen.dart:92-103](../../lib/features/my_addresses/my_addresses_screen.dart#L92-L103)).

---

### User Story 4 - Delete an address (Priority: P2)

Tap "Delete" on a row → confirmation dialog → server-side deletion.

**Why this priority**: features.md flags "Swipe-to-delete with undo" + "Set as default". Today **delete is a TODO**: the button is wired to `confirmDialog` but the on-confirm branch is empty.

**Acceptance Scenarios**:

1. **Given** the row has an `onDelete` callback wired, **When** the user taps the delete-affordance and confirms in the dialog, **Then** today **nothing happens** — `if (confirm == true) { //todo }` ([my_addresses_screen.dart:109-111](../../lib/features/my_addresses/my_addresses_screen.dart#L109-L111)).
2. Note: the delete-button itself is **commented out** in [address_item.dart:201-214](../../lib/features/my_addresses/widgets/address_item.dart#L201-L214). The `onDelete` callback is therefore never invoked in production today. Effectively dead.

---

### User Story 5 - Set as default (Priority: P2)

features.md asks for a "Set as default" action. **Not implemented.** `AddressModel` has no `isDefault` field; the bloc has no event.

---

### Edge Cases

- **Failed fetch shows empty state, not an error**: `state.addressesState.failed(message)` only sets `error`; the screen branches on `data.isEmpty` and shows `EmptyAddress`. **Surfacing the error to the user is a gap.**
- **No pagination**: `GET regions/addresses` returns the full list. Acceptable while users have ≤10 addresses; would need rework at scale.
- **Two debug prints** in the empty-state add-flow ([my_addresses_screen.dart:67, 70](../../lib/features/my_addresses/my_addresses_screen.dart#L67-L70)) — `'1111111111111111111111111111111111111111111'` and `'222222222222222222222222222222222222222222'`.
- **`SubmitMyAddressesEvent` event** exists ([my_addresses_events.dart:12](../../lib/features/my_addresses/bloc/my_addresses_events.dart#L12)) and is handled with an empty body ([my_addresses_bloc.dart:19-21](../../lib/features/my_addresses/bloc/my_addresses_bloc.dart#L19-L21)). Dead code.
- **`AddressesState.select(AreaModel)`** is defined but never called ([my_addresses_states.dart:44-46](../../lib/features/my_addresses/bloc/my_addresses_states.dart#L44-L46)). Dead code.
- **`MyAddressesBloc.initialCity` / `initialRegion`** are declared but never read ([my_addresses_bloc.dart:11-12](../../lib/features/my_addresses/bloc/my_addresses_bloc.dart#L11-L12)). Dead code.
- **`AddressModel.fromJson` reverses semantics**: JSON `state_model` maps to Dart `cityModel`, JSON `city_model` maps to Dart `regionModel` ([address_model.dart:38-41](../../lib/features/my_addresses/models/address_model.dart#L38-L41)). Matches the [add_address spec edge case](../add_address/spec.md#edge-cases) about the Dart-vs-JSON nomenclature swap.
- **No "no addresses" Arabic translation guarantee**: per features.md `ar.json` is ~40% behind; verify `no_addresses` / `add_your_address_now` keys are present.
- **`endpoint` name typo**: `eventForUserEndpoint` is the field name for the addresses endpoint in [my_addresses_repo.dart:10](../../lib/features/my_addresses/repo/my_addresses_repo.dart#L10) — left over from an earlier "events" template.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST fetch the user's addresses from `GET regions/addresses` on screen mount via `MyAddressesBloc.FetchAddresses`.
- **FR-002**: System MUST render each address as an `AddressItem` card with localized labels for name/address/city/area-or-region/(Brazil) state/complement/zip/country phone code/country name.
- **FR-003**: System MUST render `EmptyAddress` with an "Add address" CTA when the loaded list is empty.
- **FR-004**: System MUST support pull-to-refresh on the populated list.
- **FR-005**: System MUST allow editing an existing address by pushing `AddAddressScreen(addressModel: address)` and re-fetch on `pop(true)`.
- **FR-006** (gap from features.md): System MUST support "Set as default" — currently absent from `AddressModel`, the bloc, and the backend contract.
- **FR-007** (gap from features.md): System MUST support swipe-to-delete with undo, *and* must actually call a server delete endpoint (TBD).
- **FR-008** (gap): System SHOULD surface fetch failures to the user (today the failed state is silent).
- **FR-009** (gap): System SHOULD expose an "Add address" action in the app bar so users with a non-empty list can add more.

### Localization Requirements

| Key | Use site |
|---|---|
| `my_addresses` | App bar title |
| `no_addresses` | EmptyAddress heading |
| `add_your_address_now` | EmptyAddress body |
| `add_address` | EmptyAddress CTA |
| `address` | AddressItem label |
| `city` | AddressItem label |
| `area` | AddressItem label (Brazil branch) |
| `region` | AddressItem label (non-Brazil branch) |
| `state` | AddressItem label (Brazil branch only when state name resolves) |
| `complete_address` | AddressItem label |
| `zip_code` | AddressItem label |
| `country_code` | AddressItem label (phone code) |
| `country` | AddressItem label |
| `edit` | Row CTA |
| `delete_address_title`, `delete_address_content` | Delete confirmation dialog (currently dead) |

No new keys required.

### Backend Touchpoints

- **REST endpoints** (base `https://criarte.filhos.app/api/v1/`):
  - `GET regions/addresses` — list addresses for the authenticated user. Response `data` is a flat array of `AddressModel`.
- **Headers**: standard via `NetworkInterceptor`.
- **No delete / set-default endpoint** referenced from this feature today.

### Permissions & Approval Gate

- Reachable post-login via settings; approval gate enforced upstream.
- No device permissions.

### Key Entities

- **`AddressModel`** ([address_model.dart](../../lib/features/my_addresses/models/address_model.dart)) — `{cityModel, regionModel, countryModel, id, name, country_id, country, city, brazil_state_code, area, address, zip_code, complement}`. Note the JSON-vs-Dart name swap (`state_model` → `cityModel`, `city_model` → `regionModel`).
- **`MyAddressesStates`** — single-slot composite containing `AddressesState{ data, loading, error }`.
- **`MyAddressesEvents`** — `FetchAddresses`, dead `SubmitMyAddressesEvent`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A parent with 3 saved addresses sees them within 1.5 s of opening the screen on a warm network.
- **SC-002**: After adding or editing via `AddAddressScreen`, the list reflects the change without a manual refresh.
- **SC-003**: With FR-006 implemented, exactly one address is marked `isDefault: true` at any time.
- **SC-004**: With FR-007 implemented, a deleted address is removable with a 3-5 s undo window via SnackBar.

## Assumptions

- The backend at `GET regions/addresses` returns only the caller's addresses (server-side filter by token).
- No pagination is needed at current product scale.
- A future `PATCH regions/addresses/<id>` (or `POST regions/addresses/default`) will back FR-006; not specced here.
- A future `DELETE regions/addresses/<id>` will back FR-007; not specced here.
