import 'package:escola/core/errors/failures.dart';
import 'package:escola/features/add_address/models/area_model.dart';
import 'package:escola/features/diary/models/child_model.dart';

class MyChildrenStates {
  final ChildrenState childrenState;

  const MyChildrenStates({
    this.childrenState = const ChildrenState(),
  });

  MyChildrenStates copyWith({
    ChildrenState? childrenState,
  }) =>
      MyChildrenStates(
        childrenState: childrenState ?? this.childrenState,
      );

  MyChildrenStates setChildrenState(
          ChildrenState Function(ChildrenState s) setter) =>
      copyWith(
        childrenState: setter(childrenState),
      );
}

class ChildrenState {
  final List<ChildModel> data;
  final bool loading;
  final Failure? error;

  const ChildrenState({
    this.data = const [],
    this.loading = false,
    this.error,
  });

  ChildrenState get fetching => const ChildrenState(
        loading: true,
      );

  ChildrenState success(List<ChildModel> data) => ChildrenState(
        data: data,
      );

  ChildrenState select(AreaModel selected) => ChildrenState(
        data: data,
      );

  ChildrenState failed(Failure error) => ChildrenState(
        error: error,
      );
}
