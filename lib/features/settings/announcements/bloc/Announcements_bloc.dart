import 'package:escola/core/local_db/local_db_repo.dart';
import 'package:escola/features/settings/Announcements/data_source/Announcements_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../announcements/bloc/announcements_event.dart';
import '../../announcements/bloc/announcements_state.dart';

class AnnouncementsBloc extends Bloc<AnnouncementsEvent, AnnouncementsState> {
  final AnnouncementsRepo announcementsRepo;
  final LocalDatabaseRepo localDatabaseRepo;

  AnnouncementsBloc({
    required this.announcementsRepo,
    required this.localDatabaseRepo,
  }) : super(AnnouncementsInitial()) {
    on<AnnouncementsEvent>((event, emit) async {
      if (event is AnnouncementsFetchDataEvent) {
        emit(AnnouncementsLoading());
        await announcementsRepo.getAnnouncements().then((value) {
          print('announcement AnnouncementsFetchDataEvent');
          value.fold(
            (l) {
              emit(
                AnnouncementsError(failure: l),
              );
              print('announcement $l');
            },
            (announcements) {
              emit(AnnouncementsFetchedSuccessfully(announcements: announcements));
            },
          );
        });
      }
    });
  }
}
