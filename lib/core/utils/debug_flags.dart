/// App-wide debug toggles. Keep these `false` for every commit that hits
/// the default branch — production behavior must rely on Firestore config
/// and real HTTP calls.
class DebugFlags {
  /// One-stop switch for local server-driven-auth testing.
  ///
  /// When `true`:
  ///   * [Config.serverDrivenAuthEnabled] returns `true` regardless of the
  ///     Firestore `config/*` flag — so LoginScreen renders the new flow.
  ///   * `ServerDrivenAuthInjection` registers `SdaMockImpl` instead of the
  ///     real HTTP impl — so calls return canned responses keyed by the test
  ///     phone numbers documented in `specs/server_driven_auth/local-testing.md`.
  ///
  /// When `false` (default): production wiring — real HTTP, real Firestore
  /// flag.
  ///
  /// **`bool.fromEnvironment` is a compile-time const**, so this is a `const`
  /// at every call-site. **Default `true`** is the current working mode:
  /// `flutter run` lands on the new SDA flow against `SdaMockImpl`, so the
  /// app is fully usable end-to-end while the real backend is being built.
  /// The Playwright harness explicitly overrides with
  /// `--dart-define=SDA_DEV_TEST=false` (see
  /// `playwright/src/lifecycle/flutter.ts`) so legacy specs keep working.
  ///
  /// **Flip default to `false` once the real backend ships** so production
  /// relies on the Firestore `server_driven_auth_enabled` flag instead of
  /// this compile-time const.
  static const bool kSdaDevTest =
      bool.fromEnvironment('SDA_DEV_TEST', defaultValue: true);

  /// Hide the email-OTP step in `SdaMockImpl` — the mock-mode equivalent of
  /// the backend's `EMAIL_OTP_ENABLED=false` config (see
  /// `specs/server_driven_auth/contracts/email-otp.md` §3).
  ///
  /// When `true`, the mock impl returns:
  ///   * `self-register`            → `GO_TO_PENDING_APPROVAL` (no OTP screen).
  ///   * `check-identifier` for the otp-test phone (`11111110003`) →
  ///     `GO_TO_PENDING_APPROVAL` instead of `VERIFY_EMAIL_OTP`.
  ///   * `forgot-password`          → `PASSWORD_RESET_UNAVAILABLE` (per spec
  ///     §3 — reset is **blocked**, never bypassed, otherwise anyone who
  ///     knows an email could reset the target's password).
  ///   * Direct calls to `verify-email-otp` / `verify-reset-otp` →
  ///     `OTP_BYPASSED` (defense in depth — they should never be reached).
  ///
  /// Only meaningful when [kSdaDevTest] is also `true` (the mock is wired).
  /// **Default `true`** matches the product decision to skip the OTP step
  /// while the backend is being built — registration goes form → Pending
  /// Approval directly, no email step. Toggle off with
  /// `--dart-define=SDA_SKIP_OTP=false` to exercise the OTP screens
  /// manually.
  static const bool kSdaSkipOtp =
      bool.fromEnvironment('SDA_SKIP_OTP', defaultValue: true);
}