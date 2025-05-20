import 'package:equatable/equatable.dart';
import 'package:escola/core/errors/failures.dart';

sealed class EventsState extends Equatable {
  const EventsState();

  @override
  List<Object> get props => [];
}

final class EventsInitial extends EventsState {}

final class EventsError extends EventsState {
  final Failure failure;

  const EventsError({required this.failure});

  @override
  List<Object> get props => [failure];
}

final class EventsLoadingState extends EventsState {}
final class EventsSuccessState extends EventsState {}
