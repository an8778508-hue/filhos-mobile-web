import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/models/event_for_user_model.dart';
import 'package:escola/core/models/single_event_model.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/network/network_models.dart';
import 'package:escola/features/settings/accept_event/data_source/single_event_repo.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class SingleEventImpl extends SingleEventRepo {
  final NetworkClientRepository networkClient;
  SingleEventImpl({required this.networkClient});

  String convertJsonToString({required String fileName}) {
    return File(fileName).readAsStringSync();
  }

  @override
  Future<Either<Failure, SingleEventModel>> getSingleEvent({
    required String eventId,
  }) async {
    return await networkClient.handleRequest(
      NetworkRequest(method: HttpMethod.get, url: singleEventEndpoint(eventId)),
      onSuccess: (json) {
        return SingleEventModel.fromJson(json['data']);
      },
    );
  }

  @override
  Future<Either<Failure, String>> toggleApproveEvent(
      {required String eventId,
        required String userId,
        required bool isApproved}) async {
    return await networkClient.handleRequest(
      NetworkRequest(
          method: HttpMethod.post,
          url: updateEventForUserEndpoint(eventId),
          body: {
            'event_id': eventId,
            'approved': isApproved ? 1 : 0,
          }),
      onSuccess: (json) {
        return LocalizationKeys.event_not_approved_successfully;
      },
    );
  }

  @override
  Future<Either<Failure, bool>> payment({
    required String eventId,
    required XFile image,
    required String userId,
  }) async {
    print('image.path ${image.path}');
    print('image.path $eventId');
    print('image.path $userId');
    return await networkClient.handleRequest(
      NetworkRequest(
          method: HttpMethod.post,
          url: updateEventForUserEndpoint(eventId),

          body: FormData.fromMap({
            'event_id': eventId,
            'paid': 1 ,
            'image': await MultipartFile.fromFile(image.path),
          })),
      onSuccess: (json) {
        return true;
      },
    );
    // return await networkClient.handleRequest<bool>(
    //   NetworkRequest(
    //     method: HttpMethod.post,
    //     url: updateEventForUserEndpoint,
    //     body: FormData.fromMap({
    //       "event_id": eventId,
    //       "payment_image": await MultipartFile.fromFile(
    //         image.path,
    //         filename: image.path.split('/').last,
    //       ),
    //     }),
    //   ),
    //   // onSuccess: (value) => true,
    // );
  }

}

extension RepoExtension on SingleEventRepo {
  Future<Either<String, T>> _basicErrorHandling<T>({
    Future<T> Function()? onSuccess,
    Future<String> Function(Exception exception)? onOtherError,
  }) async {
    try {
      final f = await onSuccess!();
      return Right(f);
    } catch (e) {
      return const Left('server error');
    }
  }
}
