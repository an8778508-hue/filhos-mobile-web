import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/local_db/local_db_repo.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/features/settings/Announcements/bloc/Announcements_bloc.dart';
import 'package:escola/features/settings/Announcements/data_source/Announcements_impl.dart';
import 'package:escola/features/settings/Announcements/data_source/Announcements_repo.dart';

class AnnouncementsInjection implements DependencyInjection {
  @override
  void init() {
    di.registerSingleton<AnnouncementsRepo>(AnnouncementsImpl(networkClient: di<NetworkClientRepository>()));
    di.registerFactory<AnnouncementsBloc>(
      () => AnnouncementsBloc(announcementsRepo: di<AnnouncementsRepo>(), localDatabaseRepo: di<LocalDatabaseRepo>()),
    );
  }
}
