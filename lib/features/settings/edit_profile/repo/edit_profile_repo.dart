import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/network/network_models.dart';
import 'package:escola/core/utils/constants/static_config.dart';
import 'package:escola/features/settings/edit_profile/models/class_model.dart';
import 'package:escola/features/settings/edit_profile/models/title_model.dart';
import 'package:escola/flavors/app_flavors.dart';
import 'package:escola/my_app.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileRepo {
  final NetworkClientRepository networkClientRepository;

  String get editProfileEndpoint => mainKey.currentContext?.isParents == true ? "/auth/profile" : "/auth/profile";
  final String classesEndpoint = 'schools/${StaticConfig.schoolId}/classes';
  final String titlesEndpoint = 'teacher/titles';

  EditProfileRepo({required this.networkClientRepository});

  Future<Either<Failure, void>> updateProfile({
    required String phone,
    required List<String> phones,
    required List<String> emails,
    // required List<String> classes,
    required String name,
    required String? title,
    required int gender,
    required String email,
    required String cpf,
    required XFile? avatar,
  }) async {
    return networkClientRepository.handleRequest(
      NetworkRequest(
          method: HttpMethod.post,
          headers: {
            'method': 'PUT',
          },
          url: editProfileEndpoint,
          body: FormData.fromMap({
            'name': name,
            'email': email,
            'phone': phone,
            'phones': phones.map((e) => ({"number": e})).toList(),
            'emails': emails.map((e) => ({"email": e})).toList(),
            // 'classes': classes.map((e) => ({"class_id": e})).toList(),
            'gender': gender,
            if (title != null) 'title_id': title,
            'cpf': cpf,
            'cpf_num': cpf,
            if (avatar != null)
              "avatar": await MultipartFile.fromFile(
                avatar.path!,
                filename: avatar.path!.split('/').last,
              ),
          })),
      onSuccess: (json) {
        return;
      },
    );
  }

  Future<Either<Failure, List<ClassModel>>> getClasses() async {
    return networkClientRepository.handleRequest(
      NetworkRequest(
        method: HttpMethod.get,
        url: classesEndpoint,
      ),
      onSuccess: (json) {
        return (json['data'] as List).map((e) => ClassModel.fromJson(e)).toList();
      },
    );
  }

  Future<Either<Failure, List<TitleModel>>> getTitles() async {
    return networkClientRepository.handleRequest(
      NetworkRequest(
        method: HttpMethod.get,
        url: titlesEndpoint,
      ),
      onSuccess: (json) {
        return (json['data'] as List).map((e) => TitleModel.fromJson(e)).toList();
      },
    );
  }
}
