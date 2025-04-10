import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/local_db/local_db_repo.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/features/home/bloc/home_bloc.dart';
import 'package:escola/features/home/data_source/home_impl.dart';
import 'package:escola/features/home/data_source/home_repo.dart';

class HomeInjection implements DependencyInjection {
  @override
  void init() {
    // Data sources
    // di.registerLazySingleton<HomeRepo>(() => di<HomeImpl>());
    di.registerSingleton<HomeRepo>(HomeImpl(networkClient: di<NetworkClientRepository>()));
    // Bloc
    di.registerFactory<HomeBloc>(() => HomeBloc(
          homeRepo: di<HomeRepo>(),
          localDatabaseRepo: di<LocalDatabaseRepo>(),
        ));
  }
}
