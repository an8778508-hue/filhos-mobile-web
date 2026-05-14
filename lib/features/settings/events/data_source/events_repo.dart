import 'package:dartz/dartz.dart';
import 'package:escola/core/components/sheets/filter_sheet.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/models/event_model.dart';
import 'package:escola/core/models/event_generic_model.dart';
import 'package:escola/core/user/current_role.dart';

abstract class EventsRepo {
  final String professorsEventEndpoint = "events";
  final String parentsEventsEndpoint = "events";
  String get getEventsEndpoint =>
      isCurrentUserProfessor ? professorsEventEndpoint : parentsEventsEndpoint;

  Future<Either<Failure, List<EventGenericModel>>> getProfessorEvents(FilterModel? filterModel, {bool featured = false});
  Future<Either<Failure, List<EventModel>>> getProfessorDayEvents(DateTime date,FilterModel filterModel);
}
