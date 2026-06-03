import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/features/main/presentation/main_screen.dart';
import 'package:escola/features/server_driven_auth/models/auth_action.dart';
import 'package:escola/features/server_driven_auth/models/auth_action_response.dart';
import 'package:escola/features/server_driven_auth/presentation/email_otp_screen.dart';
import 'package:escola/features/server_driven_auth/presentation/pending_approval_screen.dart';
import 'package:escola/features/server_driven_auth/presentation/reset_otp_screen.dart';
import 'package:escola/features/server_driven_auth/presentation/set_initial_password_screen.dart';
import 'package:escola/features/server_driven_auth/presentation/set_new_password_screen.dart';
import 'package:escola/features/server_driven_auth/presentation/login_screen.dart' as sda_login;
import 'package:escola/features/your_account_under_review/presentation/your_account_under_review_screen.dart';
import 'package:escola/core/user/bloc/user_bloc.dart';
import 'package:flutter/material.dart';

/// The single, exhaustive mapping from server `action` → navigation. Per
/// FR-SDA-04 there is **no other `switch (action)` allowed** anywhere in the
/// app. Grep before merging: matches in `lib/features/server_driven_auth/`
/// should be in this file and nowhere else.
///
/// The dispatcher does NOT mutate cubit state — it only performs UI
/// side-effects. Cubit-level transitions for inline actions (REQUIRE_PASSWORD,
/// NOT_FOUND, ACCOUNT_SUSPENDED) live in the cubit; this dispatcher only sees
/// navigation-bound actions (those carried inside `SdaActionReady`).
class AuthActionDispatcher {
  const AuthActionDispatcher();

  /// Called from a `BlocListener` on `SdaActionReady` (or directly by the
  /// terminal-success listener for `SdaLoggedIn` → approval gate).
  void dispatch(BuildContext context, AuthActionResponse r) {
    switch (r.action) {
      case AuthAction.createNewPassword:
        _replaceWith(
          context,
          SetInitialPasswordScreen(tempToken: r.tempToken!),
        );
        return;
      case AuthAction.verifyEmailOtp:
        _push(
          context,
          EmailOtpScreen(tempToken: r.tempToken!),
        );
        return;
      case AuthAction.goToPendingApproval:
        _replaceWith(context, const PendingApprovalScreen());
        return;
      case AuthAction.verifyResetOtp:
        _push(
          context,
          ResetOtpScreen(tempToken: r.tempToken!),
        );
        return;
      case AuthAction.setNewPassword:
        _replaceWith(
          context,
          SetNewPasswordScreen(tempToken: r.tempToken!),
        );
        return;

      // The remaining four are cubit-emitted inline states or terminal —
      // they MUST NOT reach the dispatcher. Surface a localized error if
      // they ever do (defense in depth).
      case AuthAction.requirePassword:
      case AuthAction.notFound:
      case AuthAction.accountSuspended:
      case AuthAction.unknown:
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(LocalizationKeys.sda_error_unknown_action),
        ));
        return;
    }
  }

  /// Called from `BlocListener` on `SdaLoggedIn` (set-initial-password or
  /// login). Honors the approval gate (Principle VIII) by reading the freshly
  /// stored `UserBloc.state.user.isApproval`.
  void routeAfterLogin(BuildContext context) {
    final isApproved = UserBloc.get.state.user?.isApproval == true;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => isApproved
            ? const MainScreen()
            : const YourAccountUnderReviewScreen(),
      ),
      (_) => false,
    );
  }

  /// Called from `BlocListener` on `SdaResetSuccess` (reset-password). Clears
  /// the navigation stack back to LoginScreen and surfaces a success snackbar.
  void routeAfterResetSuccess(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const sda_login.LoginScreen()),
      (_) => false,
    );
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(LocalizationKeys.sda_reset_success),
    ));
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _replaceWith(BuildContext context, Widget screen) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }
}
