import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/event_bus.dart';
import 'package:escola/core/local_db/local_db_repo.dart';
import 'package:escola/features/home/data_source/home_repo.dart';
import 'package:escola/features/home/models/home_model.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> with EventBlocListener {
  final HomeRepo homeRepo;
  final LocalDatabaseRepo localDatabaseRepo;

  HomeBloc({
    required this.homeRepo,
    required this.localDatabaseRepo,
  }) : super(HomeInitial()) {
    listen((event) {
      if(event is EventAcceptedOrRejected || event is EventAdded){
        add(ReloadHomeFetchDataEvent(completer: null));
      }
    });

    on<HomeEvent>((event, emit) async {
      if (event is HomeFetchDataEvent) {
        emit(HomeLoading());
        await homeRepo.getHomeData().then((value) {
          value.fold(
            (l) => emit(HomeError(failure: l)),
            (homeModel) {
              emit(HomeFetchedSuccessfully(homeModel: homeModel));
            },
          );
        });
      }
      if (event is ReloadHomeFetchDataEvent) {
        if (!event.silent) {
          emit(HomeLoading());
        }
        await homeRepo.getHomeData().then((value) {
          event.completer?.complete();
          value.fold(
            (l) => emit(
              HomeError(failure: l),
            ),
            (homeModel) {
              emit(HomeFetchedSuccessfully(homeModel: homeModel));
              print('HomeFetchDataEvent $homeModel');
            },
          );
        });
      }
    });
  }
}
