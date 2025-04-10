import 'package:bloc/bloc.dart';
import 'package:escola/features/notifications/repo/notifications_repo.dart';

import 'notifications_events.dart';
import 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvents, NotificationsState> {
  final NotificationsRepo notificationsRepo;
  int pageNumber = 0 ;
  bool isLastPage =false ;

  NotificationsBloc({
    required this.notificationsRepo,
  }) : super(const NotificationsState()) {
    on<FetchNotifications>(
      (event, emit) async {
        if (!event.silent ) {
          emit(state.setNotificationsListState((s) => s.fetching));
        }
        final f = await notificationsRepo.getNotificationsPaginated(1);
        f.fold(
          (l) => emit(state.setNotificationsListState((s) => s.failed(l))),
          (r) => emit(state.setNotificationsListState((s) {
            pageNumber = 1 ;
            if(r.length != 10){
              isLastPage = true ;
            }
            return s.success(r);
          })),
        );
      },
    );
    on<FetchMoreNotifications>(
      (event, emit) async {
        if (state.notificationsListState.loading != null || isLastPage) {
          return;
        }
          emit(state.setNotificationsListState((s) => s.loadingMore));
        final f = await notificationsRepo.getNotificationsPaginated(pageNumber+1);
        f.fold(
          (l) => emit(state.setNotificationsListState((s) => s.failed(l))),
          (r) => emit(state.setNotificationsListState((s) {
            if(r.length != 10){
              isLastPage = true ;
            }else{
              pageNumber ++ ;
            }
            return s.successMore(r);
          })),
        );
      },
    );
    on<ReloadNotificationsEvent>(
      (event, emit) async {
        if (!event.silent) {
          emit(state.setNotificationsListState((s) => s.reloading));
        }
        final f = await notificationsRepo.getNotificationsPaginated(1);
        event.completer?.complete();
        f.fold(
          (l) => emit(state.setNotificationsListState((s) => s.failed(l))),
          (r) => emit(state.setNotificationsListState((s) {
            pageNumber = 1 ;
            if(r.length != 10){
              isLastPage = true ;
            }
            return s.success(r);
          })),
        );
      },
    );

  }
}
