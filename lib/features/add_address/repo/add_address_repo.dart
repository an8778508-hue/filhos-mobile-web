
import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/network/network_models.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/add_address/models/city_model.dart';
import 'package:escola/features/add_address/models/country_model.dart';
import 'package:escola/features/add_address/models/region_model.dart';

class AddressesRepo {
  final NetworkClientRepository networkClientRepository;

  final String countriesEndpoint = 'regions/countries';
  final String createOrAddAddressEndpoint = 'regions/addresses';

  // Fetches the states of a country. Backend `regions/states` reads `country_id`.
  String citiesEndpoint(String id) => 'regions/states?country_id=$id';

  String regionsEndpoint(String id) => 'regions/cities?state_id=$id';

  AddressesRepo(this.networkClientRepository);

  Future<Either<Failure, void>> addOrUpdateAddress({
    String? id,
    String? name,
    String? country_id,
    String? country,
    String? city_id,
    String? city,
    String? region_id,
    String? brazil_state_code,
    String? area,
    String? state,
    String? address,
    String? zip_code,
    String? complement,
  }) async {
    return networkClientRepository.handleRequest(
      NetworkRequest(method: HttpMethod.post, url: 'regions/addresses', body: {
        "address": [{
          if (validString(id)) "id": int.parse(id!),
          if (validString(name)) "name": name,
          if (validString(country_id)) "country_id": int.parse(country_id!),
          if (validString(country)) "country": country,
          if (validString(city_id)) "state": int.parse(city_id!),
          if (validString(city)) "city": city,
          if (validString(state)) "state": state,
          if (validString(region_id)) "city": int.parse(region_id!),
          if (validString(brazil_state_code)) "brazil_state_code": brazil_state_code,
          if (validString(area)) "area": area,
          if (validString(address)) "address": address,
          if (validString(zip_code)) "zip_code": zip_code,
          if (validString(complement)) "complete_address": complement,
        }
]      }),
      onSuccess: (json) {
        return;
      },
    );
  }

  Future<Either<Failure, List<CountryModel>>> getCountries() async {
    return networkClientRepository.handleRequest(
      NetworkRequest(
        method: HttpMethod.get,
        url: countriesEndpoint,
      ),
      onSuccess: (json) {
        return (json['data'] as List).map((e) => CountryModel.fromJson(e)).toList();
      },
    );
  }

  Future<Either<Failure, List<CityModel>>> getCities(String id) async {
    return networkClientRepository.handleRequest(
      NetworkRequest(
        method: HttpMethod.get,
        url: citiesEndpoint(id),
      ),
      onSuccess: (json) {
        return (json['data'] as List).map((e) => CityModel.fromJson(e)).toList();
      },
    );
  }

  Future<Either<Failure, List<RegionModel>>> getRegions(String id) async {
    return networkClientRepository.handleRequest(
      NetworkRequest(
        method: HttpMethod.get,
        url: regionsEndpoint(id),
      ),
      onSuccess: (json) {
        return (json['data'] as List).map((e) => RegionModel.fromJson(e)).toList();
      },
    );
  }

}
