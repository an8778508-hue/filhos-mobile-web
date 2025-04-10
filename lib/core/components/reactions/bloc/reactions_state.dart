import 'package:escola/core/errors/failures.dart';

import '../reactions.dart';

class ReactionsState {
  final int count;
  final MyReaction? myReaction;
  final int? countFake;
  final MyReaction? myReactionFake;
  final Failure? failure;

  const ReactionsState({
    required this.count,
    required this.myReaction,
    this.countFake,
    this.myReactionFake,
    this.failure,
  });

  MyReaction? get getMyReaction => myReactionFake ?? myReaction;

  bool get hasReacted => getMyReaction != null;

  int get getCount => countFake ?? count;
}
