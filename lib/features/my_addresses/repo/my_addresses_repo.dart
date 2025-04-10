import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/network/network_models.dart';
import 'package:escola/features/add_address/models/area_model.dart';
import 'package:escola/features/add_address/models/city_model.dart';
import 'package:escola/features/add_address/models/region_model.dart';
import 'package:escola/features/my_addresses/models/address_model.dart';

class MyAddressesRepo {
  final NetworkClientRepository networkClient;
  final String eventForUserEndpoint = 'regions/addresses';

  MyAddressesRepo({required this.networkClient});

  Future<Either<Failure, List<AddressModel>>> getAddresses() async {
    return await networkClient.handleRequest(
      NetworkRequest(method: HttpMethod.get, url: eventForUserEndpoint, ),
      onSuccess: (json) {
        return (json['data'] as List).map((e) => AddressModel.fromJson(e)).toList();
      },
    );
  }
}
