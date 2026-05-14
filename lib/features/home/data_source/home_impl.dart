import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/network/network_models.dart';
import 'package:escola/features/home/data_source/home_repo.dart';
import 'package:escola/features/home/models/home_model.dart';

class HomeImpl extends HomeRepo {
  final NetworkClientRepository networkClient;
  HomeImpl({required this.networkClient});

  String convertJsonToString({required String fileName}) {
    return File(fileName).readAsStringSync();
  }

  @override
  Future<Either<Failure, HomeModel>> getHomeData() async {
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
