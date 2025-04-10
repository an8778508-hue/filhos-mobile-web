import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/models/announcements_with_date_model.dart';

abstract class AnnouncementsRepo {
  final String announcementsEndpoint = "/teacher/announcements";
  Future<Either<Failure, List<AnnouncementsWithDateModel>>> getAnnouncements();
}
