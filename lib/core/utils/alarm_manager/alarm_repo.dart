import 'dart:convert';
import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/network/network_models.dart';
import 'package:escola/core/utils/alarm_manager/alarm_model.dart';
import 'package:escola/features/notifications/models/notification_model.dart';
import 'package:flutter/services.dart';

class AlarmRepo {
  final NetworkClientRepository networkClient;

  AlarmRepo(this.networkClient);

  Future<Either<Failure, List<AlarmModel>>> getAlarms() async {
    return await networkClient.handleRequest(
      const NetworkRequest(
        method: HttpMethod.get,
        url: 'teacher/medicines/reminders-alarms',
      ),
      onSuccess: (json) {
        final alarms = <AlarmModel>[];
        for (final activity in json['data']) {
          alarms.add(AlarmModel.fromJson(activity));
        }
        return alarms;
      },
    );
  }
}