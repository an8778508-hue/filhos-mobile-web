import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/local_db/local_db_repo.dart';
import 'package:escola/core/models/event_model.dart';
import 'package:escola/core/models/event_generic_model.dart';
import 'package:escola/core/utils/safe_x.dart';
import 'package:escola/features/settings/events/bloc/events_event.dart';
import 'package:escola/features/settings/events/bloc/events_state.dart';
import 'package:escola/features/settings/events/data_source/events_repo.dart';
import 'package:flutter/material.dart';

class EventsBloc extends Bloc<EventsEvent, EventsState> {
  final EventsRepo eventsProfessorsRepo;
  final LocalDatabaseRepo localDatabaseRepo;

  ValueNotifier<List<EventGenericModel>> professorEvents = ValueNotifier([]);
  ValueNotifier<bool> professorEventsLoading = ValueNotifier(false);
  ValueNotifier<Failure?> professorEventsFailure = ValueNotifier(null);

  ValueNotifier<List<EventModel>> singleDayEvents = ValueNotifier([]);
  ValueNotifier<bool> singleDayEventsLoading = ValueNotifier(false);
  ValueNotifier<Failure?> singleDayEventsFailure = ValueNotifier(null);

  EventsBloc({
    required this.eventsProfessorsRepo,
    required this.localDatabaseRepo,
  }) : super(EventsInitial()) {
    on<EventsEvent>((event, emit) async {
      if (event is FetchDataEvent) {
        professorEvents.value= [];
        professorEventsFailure.value = null;
        professorEventsLoading.value = true;
        await eventsProfessorsRepo.getProfessorEvents(event.filterModel).then((value) {
          value.fold(
            (l) => professorEventsFailure.value = l,
            (events) {
              professorEvents.value = events;
            },
          );
        });
        professorEventsLoading.value = false;
      }
      if (event is FetchDayEvent) {
        singleDayEventsFailure.value = null;
        singleDayEvents.value= [];
        singleDayEventsLoading.value = true;
        await eventsProfessorsRepo.getProfessorDayEvents(event.date,event.filterModel).then((value) {
          value.fold(
                (l) => singleDayEventsFailure.value = l,

            (events) {
              singleDayEvents.value = events;
            },
          );
        });
        singleDayEventsLoading.value = false;
      }
    });
  }
}
