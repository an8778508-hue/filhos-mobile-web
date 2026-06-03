import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/utils/debug_flags.dart';
import 'package:escola/features/server_driven_auth/data_sources/sda_mock_impl.dart';
import 'package:escola/features/server_driven_auth/data_sources/server_driven_auth_impl.dart';
import 'package:escola/features/server_driven_auth/data_sources/server_driven_auth_repository.dart';
import 'package:escola/features/server_driven_auth/dispatcher/auth_action_dispatcher.dart';
import 'package:escola/features/server_driven_auth/presentation/bloc/server_driven_auth_cubit.dart';

/// Mirrors `lib/features/login/login_di.dart`: repository as lazy singleton,
/// cubit as a factory (one per screen instance).
///
/// When [DebugFlags.kSdaDevTest] is `true`, the repository slot is filled by
/// the canned-response [SdaMockImpl] so the 9 screens can be driven without
/// a live backend. See `specs/server_driven_auth/local-testing.md`.
class ServerDrivenAuthInjection implements DependencyInjection {
  @override
  void init() {
    di.registerLazySingleton<ServerDrivenAuthRepository>(
      () => DebugFlags.kSdaDevTest
          ? SdaMockImpl()
          : ServerDrivenAuthImpl(di<NetworkClientRepository>()),
    );
    di.registerLazySingleton<AuthActionDispatcher>(
      () => const AuthActionDispatcher(),
    );
    di.registerFactory<ServerDrivenAuthCubit>(
      () => ServerDrivenAuthCubit(di<ServerDrivenAuthRepository>()),
    );
  }
}
