import 'package:dio/dio.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/local_db/local_db_repo.dart';
import 'package:escola/core/network/crashlytics_helper.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/network/network_interceptor.dart';

class NetworkInjection implements DependencyInjection {
  @override
  void init() {
    di.registerLazySingleton(() => Dio());

    di.registerLazySingleton<NetworkInterceptor>(
        () => DioInterceptorImpl(di<Dio>(), di<LocalDatabaseRepo>()));

    di.registerLazySingleton<CrashlyticsRepository>(() => CrashlyticsHelper());

    di.registerLazySingleton<NetworkClientRepository>(() => NetworkClient(
        di<Dio>(), di<NetworkInterceptor>(), di<CrashlyticsRepository>()));
  }
}
