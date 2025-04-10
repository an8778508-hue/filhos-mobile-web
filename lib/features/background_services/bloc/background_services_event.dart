part of 'background_services_bloc.dart';

sealed class BackgroundServicesEvent extends Equatable {
  const BackgroundServicesEvent();

  @override
  List<Object> get props => [];
}

class CallServices extends BackgroundServicesEvent {}
