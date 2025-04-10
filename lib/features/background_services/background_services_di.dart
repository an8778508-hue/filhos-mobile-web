import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/notifications_service/notifications_service.dart';
import 'package:escola/core/user/bloc/user_bloc.dart';
import 'package:escola/features/background_services/bloc/background_services_bloc.dart';
import 'package:escola/features/chat/presentation/bloc/chat_bloc.dart';

class BackgroundServicesInjection extends DependencyInjection {
  @override
  void init() {
    // bloc
    di.registerFactory<BackgroundServicesBloc>(() => BackgroundServicesBloc(
        di<ChatBloc>(), di<UserBloc>(), di<NotificationService>()));

    // services
    di.registerLazySingleton<NotificationService>(() => NotificationService());
  }
}
