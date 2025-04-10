import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/models/single_event_model.dart';
import 'package:image_picker/image_picker.dart';

abstract class SingleEventRepo {
  String singleEventEndpoint(String id) => "events/$id";
  Future<Either<Failure, SingleEventModel>> getSingleEvent({
    required String eventId,
  });
  final String eventForUserEndpoint = "/get-event-for-user";
   String updateEventForUserEndpoint(String id) => "/events/$id/participant";
   String payEventForUserEndpoint(String id) => "/events/upload-payment-receipt/$id";

  Future<Either<Failure, String>> toggleApproveEvent({
    required String eventId,
    required String userId,
    required bool isApproved,
  });

  Future<Either<Failure, bool>> payment({
    required String eventId,
    required String userId,
    required XFile image,
  });

}
