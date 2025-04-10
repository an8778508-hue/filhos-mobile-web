import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/models/announcements_with_date_model.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/network/network_models.dart';
import 'package:escola/features/settings/Announcements/data_source/Announcements_repo.dart';
import 'package:flutter/services.dart';

class AnnouncementsImpl extends AnnouncementsRepo {
  final NetworkClientRepository networkClient;
  AnnouncementsImpl({required this.networkClient});

  String convertJsonToString({required String fileName}) {
    return File(fileName).readAsStringSync();
  }

  @override
  Future<Either<Failure, List<AnnouncementsWithDateModel>>>
      getAnnouncements() async {
    await Future.delayed(const Duration(seconds: 1));
    final data = await rootBundle.loadString('assets/json/announcements.json');

    return await networkClient.handleRequest(
      NetworkRequest(method: HttpMethod.get, url: announcementsEndpoint),
      // testJson: data,
      onSuccess: (json) {
        final announcements = <AnnouncementsWithDateModel>[];
        print("announcement getAnnouncements");
        for (final announcement in json['data']) {
          print("announcement $announcement");
          announcements.add(AnnouncementsWithDateModel.fromJson(announcement));
        }

        return announcements;
      },
    );
  }
}

extension RepoExtension on AnnouncementsRepo {
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
