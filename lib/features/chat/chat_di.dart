import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/local_db/local_db_repo.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/features/chat/data_sources/chat_impl.dart';
import 'package:escola/features/chat/data_sources/chat_repository.dart';
import 'package:escola/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:escola/features/settings/my_children/repo/my_children_repo.dart';

class ChatInjection extends DependencyInjection {
  @override
  void init() {
    // Data sources
    di.registerFactory<ChatRepo>(() => di<ChatImpl>());
    di.registerFactory<ChatImpl>(() => ChatImpl(networkClient: di<NetworkClientRepository>()));
    // Bloc
    di.registerLazySingleton<ChatBloc>(
      () => ChatBloc(
        chatRepo: di<ChatRepo>(),
        localDatabase: di<LocalDatabaseRepo>(),
        myChildrenRepo: di<MyChildrenRepo>(),
      ),
    );
  }
}
