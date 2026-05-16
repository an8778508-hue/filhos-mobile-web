# Config Schema — AABAR Remote Configuration

AABAR uses the existing `ConfigCubit` / Firestore `config/*` mechanism for remote configuration. This file documents the new fields added to that document.

## Firestore path

`config/{schoolId}` — the school-specific config document (same document that drives translations, styling, and the `diary_enhancements` flag).

## New fields

### `aabar_webhook_url` *(string)*

The base URL of the AABAR n8n webhook, e.g. `https://n8n.example.com/webhook/aabar`. Trailing slash is optional; the mobile strips it before appending endpoint paths.

**Effect when set**: AABAR tile appears in `Config.get.homeSections` (via the `aabar` section entry); diary CTA renders; settings consent-audit row shows.

**Effect when empty or absent**: All AABAR surfaces are hidden. The tile does not render. Diary CTA collapses. Settings row is absent. `ConfigCubit.isAabarEnabled` returns `false`.

**Per-school vs org-wide**: The open business decision (single org-wide webhook vs per-school URL) is deferred to the product/backend team. The mobile reads one string. If per-school routing is handled server-side (one URL, server dispatches by `school_id`), this field holds the single org URL. If per-school URLs are needed, update this field per school document.

### `aabar_home_section` *(map, optional)*

If the home sections list is also managed per-school in this config document, include the AABAR section entry here:

```json
{
  "to": "aabar",
  "icon": "<icon URL>",
  "title": "aabar_tile_title"
}
```

`title` is a localization key; mobile resolves it via `.tr(context)`. `icon` is a URL to the AABAR logo asset (served from Firebase Storage or the CDN already used for other home-section icons).

> If home sections are managed via a separate CMS / admin panel, coordinate with the backend team to add the `aabar` section entry via that tool instead.

## ConfigCubit changes (mobile)

```dart
// ConfigState — add field:
final String aabarWebhookUrl;

// ConfigState.fromJson:
aabarWebhookUrl: json['aabar_webhook_url'] as String? ?? '',

// ConfigState.toJson:
'aabar_webhook_url': aabarWebhookUrl,

// ConfigCubit convenience getter:
bool get isAabarEnabled => state.aabarWebhookUrl.isNotEmpty;
```

Verify that `ConfigState` `toJson`/`fromJson` round-trip this field on a cold start (HydratedCubit requirement — constitution Principle IV).

## Testing the config

1. In Firestore console, open `config/{schoolId}`.
2. Add field `aabar_webhook_url` with value `https://your-n8n-host/webhook/aabar`.
3. Force-kill and reopen the app (to trigger ConfigCubit hydration from Firestore).
4. Confirm the AABAR tile appears on the home screen for both flavors.
5. Set the field to empty string `""`.
6. Force-kill and reopen.
7. Confirm the tile is absent and the diary CTA does not render.
