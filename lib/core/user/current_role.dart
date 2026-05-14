import 'package:escola/core/models/user_model.dart';
import 'package:escola/core/user/bloc/user_bloc.dart';
import 'package:escola/flavors/app_flavors.dart';

/// Role helpers usable outside the widget tree (interceptors, repos,
/// background isolates). Prefer these over `BuildContext.isParents` /
/// `mainKey.currentContext.isProfessors` — the latter can be null during
/// early boot and crashes when force-unwrapped.
///
/// Priority:
///   1. The authenticated user's `type` (server-truth, set after login).
///   2. The current app flavor (compile-time choice between
///      `lib/main.dart` and `lib/main_professores.dart`) — used pre-login.

bool get isCurrentUserParent {
  final t = UserBloc.get.state.user?.type;
  if (t != null) return t == UserType.parent;
  return isParentsFlavor;
}

bool get isCurrentUserProfessor {
  final t = UserBloc.get.state.user?.type;
  if (t != null) return t == UserType.professor;
  return isProfessorsFlavor;
}
