import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/user/current_role.dart';
import 'package:escola/features/home/models/home_model.dart';

abstract class HomeRepo {
  String get homeEndpoint => isCurrentUserProfessor ? "teacher/home" : "parent/home";
  Future<Either<Failure, HomeModel>> getHomeData();
}
