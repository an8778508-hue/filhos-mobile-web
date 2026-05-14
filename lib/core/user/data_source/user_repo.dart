import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/models/user_model.dart';

abstract class UserRepo {
  // Same path for both roles today — server routes by token. Kept as a getter
  // in case it diverges; flavor branching here is unnecessary.
  String get userDataEndpoint => "/auth/profile";
  final String updateDeviceTokenEndpoint = "/auth/token";

  Future<Either<Failure, UserModel>> getUser();

  Future<Either<Failure, void>> updateDeviceToken(String token,String? oldDeviceToken, String uuid);
}
