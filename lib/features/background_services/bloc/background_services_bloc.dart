import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:escola/core/notifications_service/notifications_service.dart';
import 'package:escola/core/user/bloc/user_bloc.dart';
import 'package:escola/features/chat/presentation/bloc/chat_bloc.dart';

part 'background_services_event.dart';
part 'background_services_state.dart';

class BackgroundServicesBloc
    extends Bloc<BackgroundServicesEvent, BackgroundServicesState> {
  final ChatBloc chatBloc;
  final UserBloc userBloc;

  final NotificationService notificationService;

  BackgroundServicesBloc(this.chatBloc, this.userBloc, this.notificationService)
      : super(BackgroundServicesInitial()) {
    on<BackgroundServicesEvent>((event, emit) {
      if (event is CallServices) {
        _callServices(event, emit);
      }
    });
  }
  // call services
  void _callServices(
      CallServices event, Emitter<BackgroundServicesState> emit) async {
    // configure notitifcations
    notificationService.configureNotifications();

    if (userBloc.state.user == null) return;
    // get Last Messages
    chatBloc.add(GetLastMessages());
    // get user data
    await userBloc.getUserData();
    // update device toke
    userBloc.updateDeviceToken();
  }
}
