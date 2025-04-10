import 'package:equatable/equatable.dart';

sealed class AnnouncementsEvent extends Equatable {
  const AnnouncementsEvent();

  @override
  List<Object> get props => [];
}

final class AnnouncementsFetchDataEvent extends AnnouncementsEvent {}

final class AnnouncementsFetchedSuccessfullyEvent extends AnnouncementsEvent {}
