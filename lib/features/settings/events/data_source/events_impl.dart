import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:escola/core/components/sheets/filter_sheet.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/models/event_generic_model.dart';
import 'package:escola/core/models/event_model.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/network/network_models.dart';
import 'package:escola/features/diary/models/school_item.dart';
import 'package:escola/features/settings/events/data_source/events_repo.dart';
import 'package:flutter/services.dart';

class EventsImpl extends EventsRepo {
  final NetworkClientRepository networkClient;

  EventsImpl({required this.networkClient});

  String convertJsonToString({required String fileName}) {
    return File(fileName).readAsStringSync();
  }

  @override
  Future<Either<Failure, List<EventGenericModel>>> getProfessorEvents(FilterModel? filterModel, {bool featured = false}) async {
    return await networkClient.handleRequest(
      NetworkRequest(method: HttpMethod.get, url: getEventsEndpoint, queryParameters: {
        if (featured) "is_feature": "1",
        if (filterModel?.parentOrChild != null && filterModel?.parentOrChild?.type == SchoolItemType.parentType)
          "filter[parent][]": filterModel!.parentOrChild!.id,
        if (filterModel?.parentOrChild != null && filterModel?.parentOrChild?.type == SchoolItemType.childType)
          "filter[child][]": filterModel!.parentOrChild!.id,
        if (filterModel?.levels != null) "filter[level][]": filterModel!.levels!.id,
        if (filterModel?.teacher != null) "filter[teacher][]": filterModel!.teacher!.id,
      }),
      onSuccess: (json) {
        final events = <EventGenericModel>[];
        for (final event in json['data']) {
          events.add(EventGenericModel.fromJson(event));
        }
        return events;
      },
    );
  }

  @override
  Future<Either<Failure, List<EventModel>>> getProfessorDayEvents(DateTime date, FilterModel filterModel) async {
    final year = date.year;
    final month = date.month;
    final day = date.day;
    return await networkClient.handleRequest(
      NetworkRequest(method: HttpMethod.get, url: getEventsEndpoint, queryParameters: {
        "date": "$year-$month-$day",
      }),
      onSuccess: (json) {
        final events = <EventModel>[];
        for (final event in json['data']) {
          events.add(EventModel.fromJson(event));
        }
        return events;
      },
    );
  }
}

extension RepoExtension on EventsRepo {
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
