part of 'background_services_bloc.dart';

sealed class BackgroundServicesState extends Equatable {
  const BackgroundServicesState();
  
  @override
  List<Object> get props => [];
}

final class BackgroundServicesInitial extends BackgroundServicesState {}
