part of 'all_children_bloc.dart';

sealed class AllChildrenState extends Equatable {
  const AllChildrenState();

  @override
  List<Object> get props => [];
}

final class AllChildrenInitial extends AllChildrenState {}

final class AllChildrenLoading extends AllChildrenState {}

final class AllChildrenSucceed extends AllChildrenState {
  final List<SchoolItem> items;

  const AllChildrenSucceed({required this.items});

  @override
  List<Object> get props => [items];
}

final class AllChildrenFailed extends AllChildrenState {
  final Failure failure;

  const AllChildrenFailed({required this.failure});

  @override
  List<Object> get props => [failure];
}
