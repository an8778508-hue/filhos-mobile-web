import 'package:equatable/equatable.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/models/announcements_with_date_model.dart';

sealed class AnnouncementsState extends Equatable {
  const AnnouncementsState();

  @override
  List<Object> get props => [];
}

final class AnnouncementsInitial extends AnnouncementsState {}

final class AnnouncementsLoading extends AnnouncementsState {}

final class AnnouncementsFetchedSuccessfully extends AnnouncementsState {
  final List<AnnouncementsWithDateModel> announcements;

  const AnnouncementsFetchedSuccessfully({
    required this.announcements,
  });

  @override
  List<Object> get props => [announcements];
}

final class AnnouncementsError extends AnnouncementsState {
  final Failure failure;

  const AnnouncementsError({required this.failure});

  @override
  List<Object> get props => [failure];
}
