import 'package:equatable/equatable.dart';
import 'package:escola/core/models/user_model.dart';
import 'package:escola/features/server_driven_auth/models/auth_action_response.dart';

/// State surface for [ServerDrivenAuthCubit]. Sealed so the dispatcher /
/// `BlocListener` exhaustively pattern-match every case (Dart 3 sealed types).
sealed class ServerDrivenAuthState extends Equatable {
  const ServerDrivenAuthState();
  @override
  List<Object?> get props => const [];
}

class SdaInitial extends ServerDrivenAuthState {
  const SdaInitial();
}

class SdaLoading extends ServerDrivenAuthState {
  const SdaLoading();
}

/// Emitted for navigation-bound actions (`CREATE_NEW_PASSWORD`,
/// `VERIFY_EMAIL_OTP`, `GO_TO_PENDING_APPROVAL`, `VERIFY_RESET_OTP`,
/// `SET_NEW_PASSWORD`). The screen's `BlocListener` hands [response] to
/// `AuthActionDispatcher` which performs the navigation.
class SdaActionReady extends ServerDrivenAuthState {
  final AuthActionResponse response;
  const SdaActionReady(this.response);
  @override
  List<Object?> get props => [response.action, response.tempToken];
}

/// Emitted on `REQUIRE_PASSWORD`. The login screen rebuilds to reveal the
/// inline password field — **no navigation**. FR-SDA-04.
class SdaLoginPasswordRequired extends ServerDrivenAuthState {
  final String phone;
  final String countryCode;
  const SdaLoginPasswordRequired({
    required this.phone,
    required this.countryCode,
  });
  @override
  List<Object?> get props => [phone, countryCode];
}

/// Emitted on `NOT_FOUND`. LoginScreen shows the inline "create one?" prompt.
class SdaPhoneNotFound extends ServerDrivenAuthState {
  const SdaPhoneNotFound();
}

/// Emitted on `ACCOUNT_SUSPENDED`. LoginScreen shows inline suspended error.
class SdaAccountSuspended extends ServerDrivenAuthState {
  const SdaAccountSuspended();
}

/// Terminal success — `set-initial-password` or `login` returned a JWT and
/// `UserBloc.loggedIn(user)` has been called. Screen routes via the existing
/// approval gate (Principle VIII).
class SdaLoggedIn extends ServerDrivenAuthState {
  final UserModel user;
  const SdaLoggedIn(this.user);
  @override
  List<Object?> get props => [user.id, user.accessToken];
}

/// Terminal success for Scenario 5 — `reset-password` succeeded. The
/// `SetNewPasswordScreen` shows a success snackbar and pops to LoginScreen
/// with the stack cleared.
class SdaResetSuccess extends ServerDrivenAuthState {
  const SdaResetSuccess();
}

/// Any failure. [localizedKey] is the already-resolved localization key (e.g.,
/// `sda_error_invalid_credentials`) — screens render it via `.tr(context)`.
class SdaFailure extends ServerDrivenAuthState {
  final String localizedKey;
  const SdaFailure(this.localizedKey);
  @override
  List<Object?> get props => [localizedKey];
}
