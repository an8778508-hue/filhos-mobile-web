import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/network/network_models.dart';
import 'package:escola/core/utils/constants/static_config.dart';
import 'package:escola/features/settings/about/models/about_model.dart';

class AboutRepo {
  final NetworkClientRepository networkClient;
  AboutRepo({required this.networkClient});

  final String aboutEndpoint = "schools/${StaticConfig.schoolId}/pages/about";

  Future<Either<Failure, AboutModel>> getAbout() async {
    return await networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.get,
        url: aboutEndpoint ,
      ),
      onSuccess: (json) {
        return AboutModel.fromJson(json?['data']??{});
      },
    );
  }
}
