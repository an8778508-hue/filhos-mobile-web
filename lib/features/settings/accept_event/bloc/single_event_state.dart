import 'package:equatable/equatable.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/models/single_event_model.dart';

sealed class SingleEventState extends Equatable {
  const SingleEventState();

  @override
  List<Object> get props => [];
}

final class SingleEventInitial extends SingleEventState {}

final class SingleEventLoading extends SingleEventState {}

final class SingleEventFetchedSuccessfully extends SingleEventState {
  final SingleEventModel singleEventModel;

  const SingleEventFetchedSuccessfully({
    required this.singleEventModel,
  });

  @override
  List<Object> get props => [singleEventModel];
}

final class SingleEventError extends SingleEventState {
  final Failure failure;

  const SingleEventError({required this.failure});

  @override
  List<Object> get props => [failure];
}
