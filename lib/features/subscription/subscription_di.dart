import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/features/subscription/bloc/subscription_bloc.dart';
import 'package:escola/features/subscription/repo/subscription_repo.dart';

class SubscriptionInjection implements DependencyInjection {
  @override
  void init() {
    di.registerSingleton<SubscriptionRepo>(
      SubscriptionRepo(networkClient: di<NetworkClientRepository>()),
    );

    di.registerFactory<SubscriptionBloc>(
      () => SubscriptionBloc(di<SubscriptionRepo>()),
    );
  }
}
