import 'package:dartz/dartz.dart';
import 'package:escola/flavors/app_flavors.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/features/home/models/home_model.dart';
import 'package:escola/my_app.dart';

abstract class HomeRepo {
  String get homeEndpoint => mainKey.currentContext?.isProfessors == true ? "teacher/home" : "parent/home";
  Future<Either<Failure, HomeModel>> getHomeData();
}
