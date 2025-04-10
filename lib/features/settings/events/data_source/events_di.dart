import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/local_db/local_db_repo.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/features/settings/events/bloc/events_bloc.dart';
import 'package:escola/features/settings/events/data_source/events_impl.dart';
import 'package:escola/features/settings/events/data_source/events_repo.dart';

class EventsInjection implements DependencyInjection {
  @override
  void init() {
    // Data sources
    di.registerSingleton<EventsRepo>(EventsImpl(networkClient: di<NetworkClientRepository>()));
    // Bloc
    di.registerFactory<EventsBloc>(
      () => EventsBloc(
          eventsProfessorsRepo: di<EventsRepo>(), localDatabaseRepo: di<LocalDatabaseRepo>()),
    );
  }
}
