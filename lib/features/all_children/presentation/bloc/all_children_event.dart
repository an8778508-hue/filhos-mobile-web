part of 'all_children_bloc.dart';

sealed class AllChildrenEvent extends Equatable {
  const AllChildrenEvent();

  @override
  List<Object> get props => [];
}

class GetAllChildren extends AllChildrenEvent {}
