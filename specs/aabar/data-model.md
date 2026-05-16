# Data Model: AABAR — in-app ABA chat agent

All entities are **device-local** (Cubit state, in-memory) unless marked *server-read*. No Hive persistence, no HydratedBloc. The consent ledger is server-owned; mobile only reads it.

---

## AABARMessage

The atom of the conversation. Immutable once created; replaced (not mutated) on state transition.

```dart
class AABARMessage extends Equatable {
  final String id;                        // UUID v4 generated client-side
  final AABARMessageRole role;            // user | assistant | error
  final String text;                      // user's input or assistant's reply
  final DateTime timestamp;
  final bool contextAttached;             // true when child_context was included
  final AABARErrorReason? errorReason;    // non-null when role == error

  // Computed
  bool get isUser      => role == AABARMessageRole.user;
  bool get isAssistant => role == AABARMessageRole.assistant;
  bool get isError     => role == AABARMessageRole.error;
}

enum AABARMessageRole { user, assistant, error }

enum AABARErrorReason {
  offline,      // network unavailable
  timeout,      // receive timeout exceeded (30 s)
  server,       // 4xx / 5xx / malformed JSON
  rateLimit,    // 429 — carries retryAfterSeconds
  consentFetch, // /consent-token endpoint failed
}
```

When `errorReason == rateLimit`, the Cubit stores `retryAfterSeconds: int` separately in `AABARState` (not on the message) so the UI can render the cool-down seconds without mutating the immutable message.

---

## AABARConversation

Not a separate class — encoded directly in `AABARState`. Held as a `List<AABARMessage>` plus disclaimer state.

```dart
// Represented inside AABARState:
final List<AABARMessage> messages;
final AABARDisclaimerState disclaimerState;  // full | footnote
final bool childContextTickOn;              // current tick state (non-sticky)
final bool isSending;                       // true while awaiting webhook
final int? retryAfterSeconds;              // non-null on rateLimit error
```

---

## AABARState (Cubit states)

```dart
sealed class AABARState extends Equatable {
  const AABARState();
}

// Empty conversation, disclaimer not yet acted on
class AABARInitial extends AABARState { ... }

// Conversation in progress (covers idle-between-messages and active)
class AABARConversationState extends AABARState {
  final List<AABARMessage> messages;
  final AABARDisclaimerState disclaimerState;
  final bool childContextTickOn;
  final bool isSending;
  final int? retryAfterSeconds;
  ...
}

enum AABARDisclaimerState { full, footnote }
```

Use a single `AABARConversationState` (not explosion of sub-states) so `BlocBuilder` can diff efficiently with `Equatable`. `isSending == true` drives the typing indicator; `messages.last.isError` drives the error state on the last bubble.

---

## AABARRequestPayload (wire format)

```dart
class AABARRequestPayload {
  final String prompt;
  final String role;          // "parent" | "teacher" — from UserBloc flavor
  final int schoolId;         // from UserBloc.state.user.schoolId
  final String lang;          // "pt" | "en" | "ar" — from ConfigCubit
  final AABARChildContext? childContext;  // null when tick is OFF

  Map<String, dynamic> toJson() { ... }
}
```

---

## AABARChildContext

```dart
class AABARChildContext {
  final int childId;
  final List<Activity> recentActivities;  // last N days (N=7 default, per FR-015)
  final String consentToken;              // single-use server-issued, ≤60 s TTL

  Map<String, dynamic> toJson() {
    return {
      'child_id': childId,
      'recent_activities': recentActivities.map((a) => a.toJson()).toList(),
      'consent_token': consentToken,
    };
  }
}
```

The `consentToken` is stored in the Cubit only for the duration of the send call; it is not held in any persistent state. Once the response arrives (or the request fails), the field is dropped.

---

## AABARConsentLedgerEntry *(server-read)*

Surfaces on `AabarConsentAuditScreen`. Read from `GET <webhook>/consent-list`. Never written by the mobile app.

```dart
class AABARConsentLedgerEntry extends Equatable {
  final String consentToken;
  final int childId;
  final String childName;     // included in the server response for display
  final DateTime issuedAt;
  final DateTime? usedAt;
  final DateTime? revokedAt;  // non-null if user already revoked this entry

  bool get isRevoked => revokedAt != null;
  bool get isActive  => !isRevoked && usedAt != null;
}
```

Server retains entries for 90 days (FR-021a). The mobile list only renders entries returned by the server; expired entries naturally drop off the list.

---

## AABARSuggestionChip

Statically defined from localization keys; not server-driven in v1 (remote-overridable via existing `ConfigCubit` translation overlay).

```dart
class AABARSuggestionChip extends Equatable {
  final String localizationKey;   // e.g., LocalizationKeys.aabar_chip_parent_1
  final AppFlavor flavor;         // parents | professores
}

// Static definition — instantiated in AABARCubit
const List<AABARSuggestionChip> _parentChips = [
  AABARSuggestionChip(localizationKey: LocalizationKeys.aabar_chip_parent_1, flavor: AppFlavor.parents),
  AABARSuggestionChip(localizationKey: LocalizationKeys.aabar_chip_parent_2, flavor: AppFlavor.parents),
  AABARSuggestionChip(localizationKey: LocalizationKeys.aabar_chip_parent_3, flavor: AppFlavor.parents),
  AABARSuggestionChip(localizationKey: LocalizationKeys.aabar_chip_parent_4, flavor: AppFlavor.parents),
];
// analogous _teacherChips
```

---

## AABARConsentAuditState (Cubit states)

```dart
sealed class AABARConsentAuditState extends Equatable { ... }
class AABARConsentAuditInitial extends AABARConsentAuditState { ... }
class AABARConsentAuditLoading  extends AABARConsentAuditState { ... }
class AABARConsentAuditLoaded extends AABARConsentAuditState {
  final List<AABARConsentLedgerEntry> entries;
}
class AABARConsentAuditError   extends AABARConsentAuditState { final String message; }
class AABARConsentRevoking     extends AABARConsentAuditState { final String consentToken; }
class AABARConsentRevoked      extends AABARConsentAuditState {
  final List<AABARConsentLedgerEntry> updatedEntries;
}
```

---

## ConfigCubit extension

```dart
// New field on ConfigState:
final String aabarWebhookUrl;   // empty string when not configured

// In ConfigCubit.fromJson / toJson:
'aabar_webhook_url': aabarWebhookUrl,

// Convenience getter on ConfigCubit:
bool get isAabarEnabled => state.aabarWebhookUrl.isNotEmpty;
```

This field is sourced from the Firestore `config/*` document, same as translations and styling. When the field is absent, defaults to `''` (empty string → AABAR surfaces hidden).

---

## Entity relationships

```text
UserBloc.state.user ──► school_id, role (parent/teacher) ──► AABARRequestPayload
ConfigCubit.state   ──► aabarWebhookUrl, lang ──────────────► AABARRequestPayload
                    ──► translations ──────────────────────── ► chip text, disclaimer copy

AABARCubit.state ──► AABARConversationState
  └─ messages: List<AABARMessage>
       └─ role, text, contextAttached

(consent flow only)
AABARImpl.requestConsentToken() ──► consent_token ──► AABARChildContext
AABARImpl.sendMessage(payload)   ──► answer ──────────► AABARMessage(role: assistant)

AabarConsentAuditCubit ──► AABARImpl.listConsentTokens() ──► List<AABARConsentLedgerEntry>
                       ──► AABARImpl.revokeConsentToken(token)
```

---

## Validation rules

| Entity | Field | Rule |
|--------|-------|------|
| `AABARRequestPayload` | `prompt` | non-empty; ≤ 4000 chars (client-side trim + enforce) |
| `AABARChildContext` | `recentActivities` | non-empty list; max 7 days back |
| `AABARChildContext` | `consentToken` | must be fetched fresh for every send; never reused |
| `AABARMessage` | `text` | non-empty (error messages use localization key text, not raw API body) |
| `AABARConsentLedgerEntry` | all | read-only; validated server-side |
