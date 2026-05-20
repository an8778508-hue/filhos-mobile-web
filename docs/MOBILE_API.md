# Mobile API — Filhos

This document is the **canonical contract** between the Filhos backend (this repo) and the Filhos mobile app (separate repository). It is consumed by mobile engineers; mobile-app PRs link to specific sections here.

> **Update rule.** Any change to a `/api/v1/*` route — method, path, request shape, response shape, status codes, auth, or middleware — MUST be made in the same commit/PR that changes the code. See [CLAUDE.md §2.5](../CLAUDE.md) and [.claude/commands/api-change.md](../.claude/commands/api-change.md).

---

## 1. Base

- **Base URL (prod)**: `https://<production-host>/api/v1`
- **Base URL (local)**: `http://localhost/api/v1` (via `php artisan serve` or Laravel Sail)
- **Routes file**: [platform/plugins/filhos/routes/api.php](../platform/plugins/filhos/routes/api.php)
- **Controllers**: [platform/plugins/filhos/src/Http/Controllers/API/](../platform/plugins/filhos/src/Http/Controllers/API/)
- **Postman collection** (legacy reference, may lag this doc): [Filhos.postman_collection.json](../platform/plugins/filhos/Filhos.postman_collection.json)

---

## 2. Conventions

### 2.1 Request

- **Content-Type**: `application/json` for JSON bodies. `multipart/form-data` for any endpoint accepting an image (`image`, `avatar`, `images[]`).
- **Accept-Language**: optional; controls localized strings in `message` and any translated content (`pt`, `en`, etc., per `botble/language` plugin).
- **Authorization**: `Bearer <token>` for routes under `auth:sanctum`. The token is the value returned by `POST /auth/login` under `data.token`.
- **Idempotency**: not enforced. Mobile must avoid retrying non-idempotent POSTs without user reconfirmation.

### 2.2 Standard success envelope

Botble's `BaseHttpResponse` wraps every success response in this shape:

```json
{
  "error": false,
  "data": { /* endpoint-specific */ },
  "message": "Success",
  "additional": null
}
```

HTTP status: usually **200**. The `data` field is `null`, an object, or an array depending on the endpoint.

### 2.3 Standard error envelopes

**Validation error (422)** — raised by every `FormRequest` in `src/Http/Requests/Apis/`:

```json
{
  "errors": {
    "phone": ["The phone field is required."],
    "role":  ["The selected role is invalid."]
  }
}
```

Some endpoints (e.g., chat, cities) additionally include `"statusCode": 422` at the top level — treat both shapes as equivalent.

**Authentication error (401)** — missing/invalid Sanctum token:

```json
{ "message": "Unauthenticated." }
```

**Authorization error (403)** — token valid but user lacks the required role/middleware:

```json
{ "message": "This action is unauthorized." }
```

**Business / logic error (200 with `error: true`)** — Botble convention: handler returned `->setError()`:

```json
{
  "error": true,
  "data": null,
  "message": "Invalid credentials",
  "additional": null
}
```

Mobile clients MUST check `error` on every response — a 200 with `error: true` is still a failed operation.

### 2.4 Roles

Defined in `Botble\Filhos\Enums\RoleEnum`. Values: `parent`, `teacher`.

The `role` query/body param on auth endpoints selects which user table (`fi_parents` / `fi_teachers`) to authenticate against. Once authenticated, the Sanctum token implicitly carries the role; subsequent role-scoped endpoints are gated by `parent` or `teacher` middleware.

### 2.5 IDs and timestamps

- All IDs are integers unless noted (`int64`).
- All timestamps are ISO 8601 strings in UTC (`2026-05-18T12:34:56.000000Z`).
- All money values are decimals serialized as strings (`"19.90"`) to avoid float precision loss.

### 2.6 Pagination

Where used (timeline, notifications, lists), responses follow Laravel's paginator shape:

```json
{
  "error": false,
  "data": {
    "current_page": 1,
    "data": [ /* items */ ],
    "first_page_url": "...",
    "last_page": 5,
    "per_page": 15,
    "total": 72
  },
  "message": "Success"
}
```

Mobile clients send `?page=N`. `per_page` is server-controlled; do not assume it's stable.

---

## 3. Endpoints

Grouped by middleware. All paths are relative to `/api/v1`.

### 3.A Public (no auth)

#### `POST /auth/check-user`

Check whether a phone is registered, and whether the account is archived (soft-deleted).

**Body:**
| Field | Type | Required | Rule |
| --- | --- | --- | --- |
| `phone` | string | yes | digits |
| `role` | string | yes | `parent` \| `teacher` |

**Response — exists, active:**
```json
{ "error": false, "data": { "exists": true }, "message": "User found" }
```

**Response — exists, archived:**
```json
{ "error": false, "data": { "exists": true, "archived": true }, "message": "User found but archived" }
```

**Response — not found:**
```json
{ "error": false, "data": { "exists": false }, "message": "User not found" }
```

**Errors:** 422 for missing/invalid `phone` or `role`.

---

#### `POST /auth/login`

Phone-based, passwordless login gated by a **Firebase Phone Auth ID token**. The mobile client must complete Firebase OTP (`signInWithCredential`) first and forward the resulting ID token. The backend verifies the token against Firebase before authenticating — see [LoginController::login](../platform/plugins/filhos/src/Http/Controllers/API/LoginController.php#L50) and [LoginController::verifyFirebaseIdToken](../platform/plugins/filhos/src/Http/Controllers/API/LoginController.php#L172).

**Body:**
| Field | Type | Required | Rule |
| --- | --- | --- | --- |
| `phone` | string | yes | min 11 chars; non-digits are stripped server-side |
| `role` | string | yes | `parent` \| `teacher` |
| `firebase_id_token` | string | yes\* | Firebase ID token from `signInWithCredential`. Sendable as body field or `X-Firebase-Id-Token` header. \*Bypassable in dev only via `FIREBASE_AUTH_VERIFY_LOGIN=false` |
| `country_code` | string | no | persisted on the user if provided |
| `device_token` | string | no | FCM token; persisted via `advanced-notification` plugin if active |

**Behavior:**
- Backend verifies `firebase_id_token` with the Firebase Admin SDK and confirms its `phone_number` claim matches the submitted `phone` (digits-only suffix match).
- If user exists (matched by `phone LIKE %<digits>`), authenticate via `Auth::login` — no password check.
- If user is in `onlyTrashed()`, return a **422** with `errors.phone = ["This account has been archived..."]`.
- If user does not exist, **create them in `LOCKED` status** and authenticate. The dashboard receives an `authDashboardNotification`.

**Response (success):** standard envelope, `data` = `UserResource` for the authenticated user (includes `token`, profile fields, role).

**Errors:**
- 422 with `errors.firebase_id_token` if the token is missing, expired, invalid, or its phone does not match the submitted `phone`.
- 422 on other validation or archived account.
- Lockout response after too many attempts (Laravel `ThrottlesLogins`).

---

#### `POST /auth/login-with-email`

Email+password login (used for accounts created via `/auth/register`).

**Body:**
| Field | Type | Required | Rule |
| --- | --- | --- | --- |
| `email` | string | yes | valid email |
| `password` | string | yes | min 6 |
| `role` | string | yes | `parent` \| `teacher` |
| `device_token` | string | no | FCM token |

**Response (success):** standard envelope, `data` = `UserResource`.

**Response (failure):** 200 with `error: true`, message `messages.invalid_login`.

---

#### `POST /auth/register`

Email-based registration.

**Body:**
| Field | Type | Required | Rule |
| --- | --- | --- | --- |
| `name` | string | yes | max 255 |
| `email` | string | yes | valid, unique in role table |
| `password` | string | yes | min 6, **must be sent again as `password_confirmation`** |
| `password_confirmation` | string | yes | matches `password` |
| `role` | string | yes | `parent` \| `teacher` |

**Behavior:** creates the user in `LOCKED` status pending dashboard activation.

**Response:** standard envelope, `data` = `UserResource`.

**Errors:** 422 for any rule violation (including non-unique email).

---

#### `POST /test/auth/login`

Test endpoint, aliased to `auth/login`. Mobile clients should not use this in production.

---

#### `GET /config`

Returns app-wide configuration (feature flags, branding, support contact, etc.). Shape is defined by `ConfigController::index`.

#### `GET /pages/privacy-policy`

Returns the privacy policy page body (rich HTML, localized).

#### `GET /pages/terms-conditions`

Returns the terms & conditions page body (rich HTML, localized).

---

### 3.B Authenticated (`auth:sanctum`)

All routes below require `Authorization: Bearer <token>`.

#### `GET /auth/profile`

Returns the authenticated user's profile (`UserResource` shape).

#### `POST /auth/token`

Update or refresh the device token attached to the current session.

**Body** (`UpdateTokenRequest`):
| Field | Type | Required |
| --- | --- | --- |
| `new_device_token` | string | yes |
| `old_device_token` | string | no |

#### `POST /auth/logout`

Logs the user out: revokes the current Sanctum token and (if `device_token` is supplied) removes that FCM token from the user.

**Body:**
| Field | Type | Required |
| --- | --- | --- |
| `device_token` | string | no |

---

### 3.C Authenticated + activated (`auth:sanctum`, `activated`)

All routes below additionally require the account to be in an activated state.

#### `GET /reactions/types`

List available reaction types (emoji set used in timeline/answers).

#### `DELETE /reactions/{reaction}`

Remove a reaction created by the authenticated user.

#### `POST /auth/chat`

Send a chat message / notification to a parent or teacher.

**Body** (`ChatRequest`):
| Field | Type | Required | Rule |
| --- | --- | --- | --- |
| `title` | string | yes | 1–120 |
| `message` | string | yes | 1–120 |
| `data` | object | yes | free-form payload attached to the notification |
| `receiver_id` | int | yes | teacher: parent OR teacher id; parent: teacher id only |

#### `POST /auth/profile`

Update the authenticated user's profile.

**Body** (`AuthRequest`):
| Field | Type | Required | Rule |
| --- | --- | --- | --- |
| `name` | string | yes | max 255 |
| `email` | string | yes | unique in role table (ignoring self) |
| `phone` | string | yes | unique in role table (ignoring self) |
| `avatar` | string \| file | no | URL or upload |
| `gender` | int \| string | no | `0`/`male` or `1`/`female` (normalized server-side) |
| `title_id` | int | required for teachers | `exists:fi_titles,id` |

#### `GET /auth/notifications`

Paginated list of notifications for the user.

#### `PUT /auth/notifications/{notification}`

Mark a notification as read/handled.

#### `GET /auth/change-language`

Switch the user's preferred language. (Stores locale on the user; subsequent responses honor `Accept-Language` or this stored value.)

---

#### Events — `/events/*`

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/events` | List events visible to the user |
| `GET` | `/events/{event}` | Event detail |
| `POST` | `/events/{event}/participant` | Update participation status |

**`POST /events/{event}/participant` body** (`UpdateEventParticipantRequest`):
| Field | Type | Required | Rule |
| --- | --- | --- | --- |
| `event_id` | int | yes | `exists:fi_events,id` |
| `read` | int | no | `0` \| `1` |
| `approved` | int | no | `0` \| `1` |
| `paid` | int | no | `0` \| `1` |
| `image` | file | required if `paid=1` | image upload (payment receipt) |

---

#### Regions — `/regions/*`

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/regions/addresses` | Get the user's saved addresses |
| `POST` | `/regions/addresses` | Replace the user's addresses |
| `GET` | `/regions/countries` | List countries |
| `GET` | `/regions/states` | List states |
| `GET` | `/regions/cities` | List cities for a state (requires `state_id`) |

**`GET /regions/cities`** (`CitiesRequest`):
| Query | Type | Required |
| --- | --- | --- |
| `state_id` | int | yes — `exists:states,id` |

**`POST /regions/addresses` body** (`RegionAddressRequest`):
| Field | Type | Required |
| --- | --- | --- |
| `address` | array | yes |
| `address[].country_id` | int | yes — `exists:countries,id` |
| `address[].state` | string | yes |
| `address[].city` | string | yes |
| `address[].name` | string | no |
| `address[].area` | string | no |
| `address[].brazil_state_code` | string | no |
| `address[].address` | string | no |
| `address[].complete_address` | string | no |
| `address[].zip_code` | number | no |
| `address[].email` | string | no — valid email |
| `address[].phone` | string | no |

---

### 3.D Parent-only (`auth:sanctum`, `activated`, `parent` middleware)

#### `GET /parent/home`
Parent dashboard payload (counts, recent activity, upcoming events).

#### `GET /parent/children`
List the parent's children.

#### `GET /parent/children/menus`
Children's food menus.

#### `GET /parent/children/teachers`
The parent's children's assigned teachers.

#### `GET /parent/children/medicines-history`
Historical medicine records for the parent's children.

#### Medicines — parent

| Method | Path | Body |
| --- | --- | --- |
| `GET` | `/parent/medicines/items/types` | — |
| `GET` | `/parent/medicines` | — |
| `POST` | `/parent/medicines` | `MedicineRequest` (see below) |
| `GET` | `/parent/medicines/{medicine}` | — |
| `POST` | `/parent/medicines/{medicine}` | `MedicineRequest` (update) |
| `DELETE` | `/parent/medicines/{medicine}` | — |

**`MedicineRequest` body:**
| Field | Type | Required | Rule |
| --- | --- | --- | --- |
| `name` | string | yes | max 255 |
| `dose` | number | yes | numeric |
| `dose_number_id` | int | yes | `exists:fi_medicines_items_values,id` |
| `period_id` | int | yes | `exists:fi_medicines_items_values,id` |
| `instruction_id` | int | yes | `exists:fi_medicines_items_values,id` |
| `dose_type_id` | int | yes | `exists:fi_medicines_items_values,id` |
| `child_id` | int | yes | `exists:fi_children,id` |
| `starting_date` | date | yes | must be `after:today` |
| `period_time` | number | yes | numeric |
| `tempo` | int[] | yes | each `exists:fi_medicines_items_values,id` |
| `images` | array | no | array of image refs |

#### Timeline — parent

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/parent/timeline/view` | Parent timeline feed |
| `POST` | `/parent/timeline/reactions` | Add/update a reaction on a field answer (`ReactRequest`) |
| `GET` | `/parent/timeline` (group) | `TimelineController@searchForTeachers` — search teachers visible to this parent |

**`ReactRequest` body:**
| Field | Type | Required | Rule |
| --- | --- | --- | --- |
| `react` | string | yes | reaction id/code |
| `parent_id` | int | yes | `exists:fi_parents,id` |
| `answer_id` | int | yes | `exists:fi_fields_answers,id` |

---

### 3.E Teacher-only (`auth:sanctum`, `activated`, `teacher` middleware)

#### `GET /teacher/home`
Teacher dashboard payload.

#### `GET /teacher/profile`
Teacher profile.

#### `POST /teacher/profile`
Update teacher profile (`TeacherUpdateRequest`).

| Field | Type | Required | Rule |
| --- | --- | --- | --- |
| `name` | string | yes | max 255 |
| `email` | string | yes | valid email |
| `phone` | string | yes | — |
| `avatar` | string \| file | no | — |
| `title_id` | int | yes | `exists:fi_titles,id` |
| `gender` | string | yes | — |
| `cpf_num` | string | no | max 255 |

#### `GET /teacher/titles`
Available teacher titles.

#### `GET /teacher/announcements`
Teacher announcements feed.

#### `GET /teacher/classes`
Classes assigned to this teacher.

#### `GET /teacher/children-teachers`
Other teachers for this teacher's children.

#### `GET /teacher/teacher-search`
Search for teachers (cross-listing).

#### Timeline & Questions — teacher

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/teacher/timeline` | `TimelineController@childSearch` — search children for the teacher's timeline |
| `GET` | `/teacher/questions` | List questions |
| `GET` | `/teacher/questions/data` | `TimelineController@questionData` — supporting data |
| `GET` | `/teacher/questions/answers` | List answers |
| `POST` | `/teacher/questions/answers` | Submit answers (`AnswerRequest`) |

**`AnswerRequest` body:**
| Field | Type | Required | Rule |
| --- | --- | --- | --- |
| `fields` | array | yes | non-empty |
| `fields[].value` | mixed | yes | — |
| `fields[].id` | int | yes | `exists:fi_field_items,id` |
| `fields[].is_image` | int | yes | `0` \| `1` |
| `fields[].metadata` | object | no | free-form |
| `class_id` | int | one of class/level/child required | `exists:fi_classes,id` |
| `level_id` | int | one of class/level/child required | `exists:fi_levels,id` |
| `child_id` | int | one of class/level/child required | `exists:fi_children,id` |

#### Medicines — teacher

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/teacher/medicines/requests` | Pending medicine requests for review |
| `POST` | `/teacher/medicines/requests/{medicine}` | Approve/decline (`UpdateTeacherMedicineRequest`) |
| `GET` | `/teacher/medicines/reminders` | Reminders set for this teacher |
| `PUT` | `/teacher/medicines/reminders/{reminder}` | Mark reminder read (`UpdateMedicineReminderRequest`) |
| `GET` | `/teacher/medicines/reminders-alarms` | Reminder alarms |
| `GET` | `/teacher/medicines/children/medicines-history` | Medicine history for the teacher's children |

**`UpdateTeacherMedicineRequest` body:**
| Field | Type | Required | Rule |
| --- | --- | --- | --- |
| `medicine_id` | int | yes | `exists:fi_medicines,id` |
| `status` | int | yes | `BaseStatusEnum::APPROVED` or `BaseStatusEnum::DECLINED` |
| `reason` | string | required if `status = DECLINED` | — |

**`UpdateMedicineReminderRequest` body:**
| Field | Type | Required | Rule |
| --- | --- | --- | --- |
| `reminder_id` | int | yes | `exists:fi_medicines_reminders,id` |
| `read` | int | yes | must be `1` |

---

## 4. Error catalog (mobile reference)

| HTTP | Body shape | When | Mobile handling |
| --- | --- | --- | --- |
| 200 + `error: false` | `{ error, data, message }` | Success | Use `data` |
| 200 + `error: true` | `{ error, data: null, message }` | Business failure (e.g., bad credentials, plugin disabled) | Show `message`; do **not** retry |
| 401 | `{ message: "Unauthenticated." }` | Token missing/invalid/expired | Drop the token, send user to login |
| 403 | `{ message: "This action is unauthorized." }` | Wrong role for endpoint | Treat as a programming error in mobile |
| 422 | `{ errors: { field: [msg] } }` or `{ errors, statusCode: 422 }` | `FormRequest` validation failed | Map each field to its input; show `msg` |
| 429 | (default Laravel throttle response) | Too many login attempts (lockout) | Show "try again later"; respect `Retry-After` header |
| 5xx | (Laravel error page or JSON) | Server error | Show generic error; report to crash analytics |

---

## 5. Notes for mobile engineers

- **The default `/auth/login` flow is passwordless and Firebase-gated.** The mobile client must complete Firebase Phone Auth OTP first, then forward the resulting ID token as `firebase_id_token` (body) or `X-Firebase-Id-Token` (header). The backend verifies the token against Firebase and matches its `phone_number` claim against the submitted `phone` before authenticating. Do not prompt for a password on the phone-login screen. Use `/auth/login-with-email` only for the email/password flow.
- **`/auth/login` creates the user on first call if not found**, with status `LOCKED`. The mobile flow must handle a logged-in-but-locked user (admin activation pending) — typically by showing a "pending approval" screen.
- **Archived (soft-deleted) users return 422 on login** with a specific `errors.phone` message. Show that message verbatim and direct the user to contact support.
- **Reactions, chat, profile, notifications** require `activated` middleware in addition to `auth:sanctum`. A locked user with a valid token will hit 403 on these.
- **The `/test/auth/login` route is a dev alias.** Mobile production builds must not call it.

---

## 6. Changelog

Maintain a brief changelog at the bottom of this file. One line per release, newest first. Tag breaking changes with `BREAKING:`.

- `2026-05-18`: Initial mobile contract document generated from current `/api/v1/*` routes.
