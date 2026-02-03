import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/local_db/local_db_repo.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/features/settings/accept_event/bloc/single_event_bloc.dart';
import 'package:escola/features/settings/accept_event/data_source/single_event_impl.dart';
import 'package:escola/features/settings/accept_event/data_source/single_event_repo.dart';

class SingleEventInjection implements DependencyInjection {
  @override
  void init() {
    // Data sources
    di.registerSingleton<SingleEventRepo>(SingleEventImpl(networkClient: di<NetworkClientRepository>()));
    // Bloc
    di.registerFactory<SingleEventBloc>(
      () => SingleEventBloc(singleEventsRepo: di<SingleEventRepo>(), localDatabaseRepo: di<LocalDatabaseRepo>()),
    );
  }
}
