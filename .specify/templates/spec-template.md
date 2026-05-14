# Feature Specification: [FEATURE NAME]

**Feature Branch**: `[###-feature-name]`

**Created**: [DATE]

**Status**: Draft

**Input**: User description: "$ARGUMENTS"

## Flavor Scope *(mandatory for Criarte)*

<!--
  Criarte ships as two flavors from one codebase: `parents` and `professores`.
  State which flavor(s) this feature targets and whether behavior diverges.
-->

- **Target flavor(s)**: [parents | professores | both]
- **Flavor-conditional behavior**: [Describe any UI/permission differences between flavors, or "Identical in both flavors"]
- **Server role implication**: [If both flavors, note that the role header is set from the flavor at login — see lib/features/login/data_sources/login_impl.dart]

## User Scenarios & Testing *(mandatory)*

<!--
  IMPORTANT: User stories should be PRIORITIZED as user journeys ordered by importance.
  Each user story/journey must be INDEPENDENTLY TESTABLE - meaning if you implement just ONE of them,
  you should still have a viable MVP (Minimum Viable Product) that delivers value.

  Assign priorities (P1, P2, P3, etc.) to each story, where P1 is the most critical.
  Think of each story as a standalone slice of functionality that can be:
  - Developed independently
  - Tested independently
  - Deployed independently
  - Demonstrated to users independently
-->

### User Story 1 - [Brief Title] (Priority: P1)

[Describe this user journey in plain language]

**Why this priority**: [Explain the value and why it has this priority level]

**Independent Test**: [Describe how this can be tested independently - e.g., "Can be fully tested by [specific action] and delivers [specific value]"]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]
2. **Given** [initial state], **When** [action], **Then** [expected outcome]

---

### User Story 2 - [Brief Title] (Priority: P2)

[Describe this user journey in plain language]

**Why this priority**: [Explain the value and why it has this priority level]

**Independent Test**: [Describe how this can be tested independently]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]

---

### User Story 3 - [Brief Title] (Priority: P3)

[Describe this user journey in plain language]

**Why this priority**: [Explain the value and why it has this priority level]

**Independent Test**: [Describe how this can be tested independently]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]

---

[Add more user stories as needed, each with an assigned priority]

### Edge Cases

<!--
  ACTION REQUIRED: The content in this section represents placeholders.
  Fill them out with the right edge cases.
-->

- What happens when [boundary condition]?
- How does system handle [error scenario]?
- How does the feature behave on the **non-target flavor**, if any user could reach it?
- How does the feature behave for a user whose `isApproval == false` (approval gate)?

## Requirements *(mandatory)*

<!--
  ACTION REQUIRED: The content in this section represents placeholders.
  Fill them out with the right functional requirements.
-->

### Functional Requirements

- **FR-001**: System MUST [specific capability]
- **FR-002**: System MUST [specific capability]
- **FR-003**: Users MUST be able to [key interaction]
- **FR-004**: System MUST [data requirement]
- **FR-005**: System MUST [behavior]

*Example of marking unclear requirements:*

- **FR-006**: System MUST [behavior] [NEEDS CLARIFICATION: detail not specified]

### Localization Requirements *(mandatory for any user-visible text)*

- All user-visible strings MUST be added as keys in `lib/core/localization/localization_keys.dart`.
- Translations MUST be provided for **all three** languages: Portuguese (primary), English, Arabic.
- List every new key here:

| Key           | pt (primary) | en        | ar     |
|---------------|--------------|-----------|--------|
| `example_key` | "Exemplo"    | "Example" | "مثال" |

- Note any string that should be **remote-overridable** via Firestore `config/*` (default: yes, since `ConfigCubit` already overlays remote translations).

### Backend Touchpoints *(include if feature talks to a backend)*

- **REST endpoints** (base `https://criarte.filhos.app/api/v1/`): [List endpoint, method, expected request/response shape]
- **Firestore collections**: [Only for chat or other realtime surfaces. Specify path patterns, e.g., `chats/{conversationId}/messages/{messageId}`]
- **Firebase Storage paths**: [If uploading media, specify path convention]
- **FCM topics / data payload keys**: [If push-notification driven, specify `eventable_id` / `eventable_type` semantics for deep linking]

### Permissions & Approval Gate

- Does this feature require `isApproval == true`? [Yes / No — explain]
- Any deep-link or push handler added by this feature MUST short-circuit to `your_account_under_review` when `isApproval == false`.
- Does it require any device permissions (camera, mic, storage, notifications, alarms)? [List]

### Key Entities *(include if feature involves data)*

- **[Entity 1]**: [What it represents, key attributes without implementation]. [If extending an existing model in `lib/core/models/` or a feature `models/` folder, name it.]
- **[Entity 2]**: [What it represents, relationships to other entities]

## Success Criteria *(mandatory)*

<!--
  ACTION REQUIRED: Define measurable success criteria.
  These must be technology-agnostic and measurable.
-->

### Measurable Outcomes

- **SC-001**: [Measurable metric]
- **SC-002**: [Measurable metric]
- **SC-003**: [User satisfaction metric]
- **SC-004**: [Business metric]

## Assumptions

<!--
  ACTION REQUIRED: The content in this section represents placeholders.
  Fill them out with the right assumptions based on reasonable defaults
  chosen when the feature description did not specify certain details.
-->

- [Assumption about target users]
- [Assumption about scope boundaries]
- [Assumption about data/environment]
- [Dependency on existing system/service]
