import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/features/server_driven_auth/dispatcher/auth_action_dispatcher.dart';
import 'package:escola/features/server_driven_auth/presentation/bloc/server_driven_auth_state.dart';
import 'package:flutter/material.dart';

/// The standard `BlocListener` reaction every server-driven-auth screen
/// applies to `ServerDrivenAuthState`. Extracted to one helper so each screen
/// reacts identically without duplicating the dispatch logic.
///
/// - `SdaActionReady` → delegate to the dispatcher (navigation).
/// - `SdaLoggedIn`    → dispatcher routes through the approval gate.
/// - `SdaResetSuccess`→ dispatcher clears stack to LoginScreen + snackbar.
/// - `SdaFailure`     → surface the localized message via SnackBar.
class SdaScreenReactions {
  const SdaScreenReactions(this.dispatcher);
  final AuthActionDispatcher dispatcher;

  void onState(BuildContext context, ServerDrivenAuthState state) {
    if (state is SdaActionReady) {
      dispatcher.dispatch(context, state.response);
    } else if (state is SdaLoggedIn) {
      dispatcher.routeAfterLogin(context);
    } else if (state is SdaResetSuccess) {
      dispatcher.routeAfterResetSuccess(context);
    } else if (state is SdaFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.localizedKey.tr(context))),
      );
    }
  }
}
