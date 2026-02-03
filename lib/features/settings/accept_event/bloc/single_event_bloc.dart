import 'package:bloc/bloc.dart';
import 'package:escola/core/event_bus.dart';
import 'package:escola/core/local_db/local_db_repo.dart';
import 'package:escola/core/models/single_event_model.dart';
import 'package:escola/core/user/bloc/user_bloc.dart';
import 'package:escola/features/settings/accept_event/bloc/single_event_event.dart';
import 'package:escola/features/settings/accept_event/bloc/single_event_state.dart';
import 'package:escola/features/settings/accept_event/data_source/single_event_repo.dart';
import 'package:flutter/material.dart';

class SingleEventBloc extends Bloc<SingleEventEvent, SingleEventState> {
  final SingleEventRepo singleEventsRepo;
  final LocalDatabaseRepo localDatabaseRepo;

  ValueNotifier<SingleEventModel?> singleEventModel = ValueNotifier(null);

  SingleEventBloc({
    required this.singleEventsRepo,
    required this.localDatabaseRepo,
  }) : super(SingleEventInitial()) {
    on<SingleEventEvent>((event, emit) async {
      if (event is FetchSingleEvent) {
        emit(SingleEventLoading());
          await singleEventsRepo
              .getSingleEvent(
            eventId: event.eventId,
          )
              .then((value) {
            value.fold(
              (l) => emit(
                SingleEventError(failure: l),
              ),
              (singleEvent) async {
                singleEventModel.value = singleEvent;
                emit(SingleEventFetchedSuccessfully(
                  singleEventModel: singleEventModel.value!,
                ));
              },
            );
          });
      }
      if (event is ApproveEvent) {
        emit(SingleEventLoading());
        final user = UserBloc.get.state.user;
        // final user = await localDatabaseRepo.getUser();

        await singleEventsRepo
            .toggleApproveEvent(
          eventId: event.eventId,
          userId: user != null ? user.id.toString() : '1',
          isApproved: true,
        )
            .then((value) {
          value.fold(
            (l) {
              emit(
                SingleEventError(failure: l),
              );
            },
            (value) {
              eventBus.fire(EventAcceptedOrRejected());
              add(FetchSingleEvent(eventId: event.eventId));
            },
          );
        });
      }
      if (event is NotApproveEvent) {
        emit(SingleEventLoading());
        final user = UserBloc.get.state.user;
        // final user = await localDatabaseRepo.getUser();
        await singleEventsRepo
            .toggleApproveEvent(
          eventId: event.eventId,
          userId: user != null ? user.id.toString() : '',
          isApproved: false,
        )
            .then((value) {
          value.fold(
            (l) {
              emit(
                SingleEventError(failure: l),
              );
            },
            (value) {
              eventBus.fire(EventAcceptedOrRejected());
              add(FetchSingleEvent(eventId: event.eventId));
            },
          );
        });
      }
      if (event is PaymentEvent) {
        emit(SingleEventLoading());
        final user = UserBloc.get.state.user;
        // final user = await localDatabaseRepo.getUser();
        await singleEventsRepo
            .payment(
          eventId: event.eventId,
          image: event.image,
          userId: user != null ? user.id.toString() : '',
        )
            .then((value) {
          value.fold(
            (l) {
              emit(
                SingleEventError(failure: l),
              );
            },
            (value) {
              add(FetchSingleEvent(eventId: event.eventId));
            },
          );
        });
      }
    });
  }
}
