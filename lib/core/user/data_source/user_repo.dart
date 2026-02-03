import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/models/user_model.dart';
import 'package:escola/my_app.dart';
import 'package:escola/flavors/app_flavors.dart';

abstract class UserRepo {
  String get  userDataEndpoint  => mainKey.currentContext?.isParents == true ?"/auth/profile":"auth/profile";
  final String updateDeviceTokenEndpoint = "/auth/token";

  Future<Either<Failure, UserModel>> getUser();

  Future<Either<Failure, void>> updateDeviceToken(String token,String? oldDeviceToken, String uuid);
}
