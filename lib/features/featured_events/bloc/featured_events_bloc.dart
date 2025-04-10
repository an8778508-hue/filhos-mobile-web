import 'package:bloc/bloc.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/local_db/local_db_repo.dart';
import 'package:escola/core/models/event_model.dart';
import 'package:escola/features/settings/events/data_source/events_repo.dart';

import 'featured_events_state.dart';

class FeaturedEventsBloc extends Cubit<FeaturedEventsState> {
  FeaturedEventsBloc(this.eventsRepo) : super(const FeaturedEventsState());

  final EventsRepo eventsRepo;

  fetch() async {
    emit(state.updateEventsState((s) => s.asLoading()));
    final f = await eventsRepo.getProfessorEvents(null,featured: true);
    f.fold(
      (l) => emit(state.updateEventsState((s) => s.asFailed(l))),
      (r) async {
        await getCache();
        final events = r.fold<List<EventModel>>(<EventModel>[], (p, c) => <EventModel>[...p, ...c.events]);
        final data = events.where((event) => !seenIds.any((id) => event.id == id)).toList();
        emit(state.updateEventsState((s) => s.asSuccessfullyLoaded(data)));
      },
    );
  }

  List<String> seenIds = [];

  getCache() async {
    seenIds = (await di<LocalDatabaseRepo>().read(key: LocalKeys.seenFeaturedEvents)) ?? <String>[];
  }

  Future cache(String id) async {
    seenIds.add(id);
    await di<LocalDatabaseRepo>().write(key: LocalKeys.seenFeaturedEvents, value: seenIds);
  }
}
