import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:escola/flavors/app_flavors.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/network/network_models.dart';
import 'package:escola/features/home/data_source/home_repo.dart';
import 'package:escola/features/home/models/home_model.dart';
import 'package:escola/my_app.dart';
import 'package:flutter/services.dart';

class HomeImpl extends HomeRepo {
  final NetworkClientRepository networkClient;
  HomeImpl({required this.networkClient});

  String convertJsonToString({required String fileName}) {
    return File(fileName).readAsStringSync();
  }

  @override
  Future<Either<Failure, HomeModel>> getHomeData() async {
    // final data = await rootBundle.loadString(
    //     'assets/json/${mainKey.currentContext!.isProfessors ? 'home_professors' : 'home'}.json');

    return await networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.get,
        url: homeEndpoint,
      ),
      // testJson: data,
      onSuccess: (json) {
        final cards = HomeModel.fromJson(json?['data'] ?? {});
        return cards;
      },
    );
  }
}
