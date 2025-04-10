import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/network/network_models.dart';
import 'package:escola/core/utils/constants/static_config.dart';
import 'package:escola/core/utils/valid_data.dart';

class TermsRepo {
  final NetworkClientRepository networkClient;

  TermsRepo({required this.networkClient});

  final String privacyEndpoint = "pages/privacy-policy";
  final String termsEndpoint = "pages/terms-conditions";

  Future<Either<Failure, String>> getPrivacy() async {
    return await networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.get,
        url: privacyEndpoint,
      ),
      onSuccess: (json) {
        return validateString(json?['data']?['content']);
      },
    );
  }

  Future<Either<Failure, String>> getTerms() async {
    return await networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.get,
        url: termsEndpoint,
      ),
      onSuccess: (json) {
        return validateString(json?['data']?['content']);
      },
    );
  }
}
