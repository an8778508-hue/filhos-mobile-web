import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/local_db/local_db_repo.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/user/bloc/user_bloc.dart';
import 'package:escola/core/user/data_source/user_impl.dart';
import 'package:escola/core/user/data_source/user_repo.dart';

class UserInjection implements DependencyInjection {
  @override
  void init() {
    // Data sources
    di.registerFactory<UserRepo>(() => di<UserDataImpl>());
    di.registerFactory<UserDataImpl>(
        () => UserDataImpl(networkClient: di<NetworkClientRepository>()));
    // Bloc
    di.registerSingleton<UserBloc>(UserBloc(di<LocalDatabaseRepo>(), di<UserRepo>()));
  }
}
