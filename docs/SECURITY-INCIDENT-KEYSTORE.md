# Security incident — leaked Android upload keystore

## Status

- **Identified:** 2026-05-13 (review.md §1)
- **Severity:** P0 — upload signing key + plaintext password (`123456`) committed to a public GitHub repository (`Evunity/filhos-mobile`).
- **Remediation in code:** the keystore, key.properties, Firebase per-flavor configs, and `android/app/google-services.json` have been removed from the git index (`git rm --cached`) and added to `.gitignore` (this commit / branch).
- **Remediation NOT yet done (requires human + external accounts):**
  1. **Rotate the upload signing key in Play Console.**
  2. **Scrub git history** so the keystore can no longer be downloaded from the public repo.
  3. **Rotate Firebase config exposure** (App Check enforcement, optional key rotation).

## Why "untrack + .gitignore" is NOT sufficient

`git rm --cached` removes the file from the *current* commit only. The file is still in the repository's history (`git log -- android/key.keystore` will show it; `git checkout <old-sha> -- android/key.keystore` will recover it). Anyone who cloned the repo before the fix already has the keystore. GitHub's commit-search and the GitHub clone of every fork also still have it.

Treat the upload key as **permanently compromised** — even if you scrub history today, copies exist.

## Required follow-up — Android

1. **In Play Console** (Setup → App integrity → App signing):
   - Confirm "Play App Signing" is enabled (it is enabled by default for new apps since Aug 2021).
   - Use **"Request upload key reset"** to upload a new key. Google holds the *app* signing key separately, so a leaked upload key does not let an attacker re-sign existing builds — but it does let them push new versions to the same listing if they reach the Play Console, so rotating is essential.
   - Generate a new keystore: `keytool -genkey -v -keystore android/key.keystore -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
   - Store the new keystore + passwords in a CI secret store (GitHub Actions encrypted secret, 1Password, GCP Secret Manager).

2. **Update CI** to fetch the keystore from secrets at build time. The new `.gitignore` blocks accidental re-commit.

3. **(Optional, recommended)** Rewrite git history to remove the keystore + key.properties from prior commits:

```bash
# Mirror clone, do NOT operate on your working repo.
git clone --mirror git@github.com:Evunity/filhos-mobile.git
cd filhos-mobile.git
pip install git-filter-repo
git filter-repo --invert-paths \
  --path android/key.keystore \
  --path android/key.properties \
  --path android/app/google-services.json \
  --path android/app/src/parents/google-services.json \
  --path android/app/src/professores/google-services.json \
  --path ios/config/parents/GoogleService-Info.plist \
  --path ios/config/professores/GoogleService-Info.plist
git push --force --all
git push --force --tags
```

**This rewrites history and will break every existing clone and PR.** Coordinate with the team before running it. Disable branch protection on `main` temporarily; re-enable after the force-push.

## Required follow-up — Firebase

The Firebase config files (`google-services.json`, `GoogleService-Info.plist`) are not "secrets" in the strict sense — they identify the app to Firebase, and the API keys inside them are not authentication credentials. **But** with the keys public, anyone can:

- Send FCM messages targeted at your senderId (only if your server-side keys leak too — they did not in this incident).
- Initialize Firebase against your project in their own app and abuse free-tier quotas.

Mitigations:

1. **Enable Firebase App Check** in the Firebase Console for every product (Firestore, Storage, Auth, Realtime DB if used). App Check rejects requests that don't come from your real app binary.
2. **Restrict the Firebase API key** in Google Cloud Console → APIs & Services → Credentials → "Firebase API Key" → "Application restrictions" to the Android `applicationId` and the iOS `bundleId`.
3. Move the configs to CI secrets (already done in `.gitignore`).

## Required follow-up — repository

- [ ] Run the `git filter-repo` block above on a coordination window.
- [ ] Force-push to all remotes.
- [ ] Tell every developer to re-clone (their local clones still have the old history).
- [ ] Verify no fork on GitHub still has the keystore (`gh search code "key.keystore" --repo Evunity/filhos-mobile` and check forks).
- [ ] Audit any user who has cloned the repo: if they're a third party, rotate any secret they might know.
