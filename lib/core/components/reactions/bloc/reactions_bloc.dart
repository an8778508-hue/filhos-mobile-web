import 'package:bloc/bloc.dart';
import 'package:escola/core/components/reactions/bloc/reactions_state.dart';
import 'package:escola/core/components/reactions/reactions.dart';
import 'package:escola/core/errors/failures.dart';

class ReactionsBloc extends Cubit<ReactionsState> {
  ReactionsBloc(int count, MyReaction? myReaction) : super(ReactionsState(count: count, myReaction: myReaction));

  sendReaction(MyReaction? reaction) async {
    int count = state.getCount;
    if (state.hasReacted) {
      if (reaction == null) {
        count--;
      }
    } else {
      if (reaction != null) {
        count++;
      }
    }
    emit(ReactionsState(
      count: state.count,
      myReaction: reaction == null ? null : state.myReaction,
      countFake: count,
      myReactionFake: reaction,
    ));
    await Future.delayed(const Duration(seconds: 2));
    if (true) {
      emit(ReactionsState(
        count: state.getCount,
        myReaction: reaction,
      ));
    } else {
      emit(ReactionsState(
        count: state.count,
        myReaction: state.myReaction,
        failure: const ServerFailure(message: 'TEST'),
      ));
    }
  }
}
