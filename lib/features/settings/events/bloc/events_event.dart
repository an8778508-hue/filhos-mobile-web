import 'package:equatable/equatable.dart';
import 'package:escola/core/components/sheets/filter_sheet.dart';

sealed class EventsEvent extends Equatable {
  const EventsEvent();

  @override
  List<Object> get props => [];
}

final class FetchDataEvent extends EventsEvent {
  final FilterModel filterModel;

  FetchDataEvent({required this.filterModel});
}

final class FetchDayEvent extends EventsEvent {
  final DateTime date;
  final FilterModel filterModel;
  const FetchDayEvent({required this.date, required this.filterModel});
}

final class FetchedSuccessfullyEvent extends EventsEvent {}

final class FetchedDaySuccessfullyEvent extends EventsEvent {}
