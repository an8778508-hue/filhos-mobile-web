# Firestore Contract — Trigger Email Extension

> **Mobile note**: this contract is **server-side only**. The mobile app does NOT write or read either of these collections. This file exists to document the backend ↔ Firebase Extension boundary so the spec is self-contained.

The Firebase Extension **"Trigger Email from Firestore"** (`firebase/firestore-send-email`, official extension) is configured to watch a Firestore collection. Whenever a new document is added to that collection, the extension renders + sends the email via configured SMTP (SendGrid for this feature).

Two collections are involved:
1. **`mail/{autoId}`** — work-queue collection the extension watches
2. **`email_templates/email_otp_{lang}`** — copy templates read by the backend before writing to `mail/`

---

## `mail/{autoId}` — work queue

Backend writes one document per OTP send. Document is auto-id (Firestore-generated). Extension subscribes to writes and dispatches.

### Write shape (backend → Firestore)

```json
{
  "to": ["parent@example.com"],

  "message": {
    "subject": "Seu código Criarte: 123456",
    "html": "<html><body><h1>Seu código</h1><p style='font-size:32px'>123456</p><p>Expira em 5 minutos.</p></body></html>",
    "text": "Seu código Criarte é: 123456\n\nEle expira em 5 minutos.\n\nSe você não pediu este código, ignore este e-mail."
  }
}
```

| Field | Type | Notes |
|---|---|---|
| `to` | `string[]` | Exactly one entry: the user's email. The extension supports multiple recipients but we never use it. |
| `message.subject` | `string` | Rendered from `email_templates/email_otp_{lang}.subject_template` with `{{code}}` substituted. |
| `message.html` | `string` | Rendered from `html_template`. |
| `message.text` | `string` | Rendered from `text_template`. Plain-text fallback for clients that don't render HTML. |

### Extension-written fields (we observe, never write)

The extension augments the document as delivery progresses:

```json
{
  "delivery": {
    "state": "SUCCESS",
    "attempts": 1,
    "endTime": "<timestamp>",
    "info": {
      "messageId": "<sendgrid-id@smtp.sendgrid.net>",
      "accepted": ["parent@example.com"],
      "rejected": [],
      "pending": []
    }
  }
}
```

Possible `state` values:
- `PENDING` — document seen, not yet picked up
- `PROCESSING` — extension is dispatching
- `SUCCESS` — SMTP accepted the message
- `ERROR` — SMTP rejected or a retry-exhausted failure occurred; check `delivery.error`

### Retention

The extension does not auto-delete `mail/{autoId}` documents. Two options for cleanup:

1. **Backend Cloud Function** — scheduled job that deletes `mail/*` where `delivery.state == "SUCCESS"` and `endTime < 30 days ago`. **Recommended** for LGPD minimization (the rendered email body contains the plain-text OTP code; keeping it forever is a liability).
2. **Manual** — accept the storage cost and add a manual purge step to ops runbook.

Recommendation: option 1. The cleanup job is ~20 lines of Node.

### Backend observability

The backend can monitor `delivery.state` to detect SMTP-tier failures:
- Periodic query for `delivery.state == "ERROR"` over the last hour
- Alert if error rate > 5% — likely a SendGrid credential issue or a deliverability problem

The mobile app does not need delivery observability — it relies on the user reporting "I didn't get the email" via the existing in-app support channels.

---

## `email_templates/email_otp_{lang}` — copy

One doc per language. Backend reads at startup and on document update (Firestore listener), substitutes `{{code}}`, and writes the rendered body into `mail/{autoId}`.

### Document shape

```json
{
  "subject_template": "Seu código Criarte: {{code}}",
  "html_template": "<!DOCTYPE html><html lang=\"pt-BR\"><body style=\"font-family: -apple-system, ...\">\n  <table align=\"center\" width=\"480\">\n    <tr><td>\n      <h1>Seu código de verificação</h1>\n      <div style=\"font-size: 36px; letter-spacing: 6px; padding: 24px; background: #f5f5f5; text-align: center;\"><strong>{{code}}</strong></div>\n      <p>O código expira em 5 minutos.</p>\n      <p style=\"color: #888; font-size: 12px;\">Se você não pediu este código, ignore este e-mail.</p>\n    </td></tr>\n  </table>\n</body></html>",
  "text_template": "Seu código Criarte é: {{code}}\n\nEle expira em 5 minutos.\n\nSe você não pediu este código, ignore este e-mail.",
  "updated_at": "<timestamp>"
}
```

Three docs required for v1:
- `email_templates/email_otp_pt` — PT-BR (primary)
- `email_templates/email_otp_en` — English
- `email_templates/email_otp_ar` — Arabic (TBD by localization team; backend falls back to PT if `ar` doc is missing)

### Variables available to templates

| Variable | Notes |
|---|---|
| `{{code}}` | The 6-digit OTP code |
| `{{expires_in_minutes}}` *(optional)* | The TTL — currently always 5; safer to hardcode in the template than vary by record |
| `{{user_first_name}}` *(optional)* | Personalization — if backend has it from the lookup, can include "Olá, {{user_first_name}}" |

Backend uses simple `{{var}}` substitution (no Mustache/Handlebars engine needed — keep dependency surface small).

### Admin editing

These docs are editable via:
- Firestore console (manual)
- Admin web app (preferred — add a "Templates" panel)
- A backend admin endpoint (lowest priority — only if Firestore-console UX is insufficient)

Edits take effect on the **next** OTP send (backend reloads on document change via a Firestore listener).

---

## Security rules (server-side enforcement)

The mobile app never touches either collection. Firestore security rules should reflect this:

```text
match /mail/{docId} {
  allow read:  if request.auth != null && hasAdminRole();   // ops/support only
  allow write: if false;                                     # backend uses Admin SDK, bypasses rules
}

match /email_templates/{templateId} {
  allow read:  if false;                                     # backend reads with Admin SDK
  allow write: if request.auth != null && hasAdminRole();
}
```

If admin web manages templates, the rules need to grant write to authenticated admins. Coordinate with backend team — the exact admin-role predicate matches the existing pattern used elsewhere in the rules file.

---

## Extension installation cheat-sheet

For the backend / ops team installing this for the first time:

1. Firebase Console → Extensions → "Trigger Email from Firestore" → Install.
2. Configure:
   - **SMTP connection URI**: `smtps://apikey:<SENDGRID_API_KEY>@smtp.sendgrid.net:465`
   - **Default FROM address**: `noreply@criarte.filhos.app` (must have DKIM/SPF configured)
   - **Default REPLY-TO**: (leave blank or use a no-reply alias)
   - **Email documents collection**: `mail`
   - **Users collection**: leave blank (we don't use the user-lookup feature)
   - **Templates collection**: leave blank (we render templates server-side; the extension's built-in template engine is not used)
3. Verify the extension installs cleanly. The console will show a green "Active" badge.
4. Test: write a sample doc to `mail/test` with a real recipient; confirm `delivery.state` reaches `SUCCESS` within ~30 s.

Estimated install time: 15 minutes (excluding DKIM/SPF DNS propagation, which can take up to 24 h).
