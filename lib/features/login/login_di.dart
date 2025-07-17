import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/local_db/local_db_repo.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/features/login/data_sources/login_impl.dart';
import 'package:escola/features/login/data_sources/login_repository.dart';
import 'package:escola/features/login/presentation/bloc/login_bloc.dart';
import 'package:escola/features/register/bloc/register_bloc.dart';

class LoginInjection implements DependencyInjection {
  @override
  void init() {
    // Data sources
    di.registerLazySingleton<LoginRepository>(() => di<LoginImpl>());
    di.registerLazySingleton<LoginImpl>(
        () => LoginImpl(di<NetworkClientRepository>()));
    // Bloc
    di.registerFactory<LoginBloc>(() => LoginBloc(
          di<LoginRepository>(),
          di<LocalDatabaseRepo>(),
        ));

    di.registerFactory<RegisterBloc>(() => RegisterBloc(
      di<LoginRepository>(),
    ));
  }
}
