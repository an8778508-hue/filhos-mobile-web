import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/network/network_models.dart';
import 'package:escola/features/settings/edit_profile/models/class_model.dart';
import 'package:escola/features/settings/edit_profile/models/title_model.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileRepo {
  final NetworkClientRepository networkClientRepository;

  // Same endpoint for both roles — server routes by token.
  final String editProfileEndpoint = "/auth/profile";
  // Backend route is `teacher/classes` (ClassController@index); there is no
  // `schools/{id}/classes` endpoint. Note: getClasses() is currently only
  // referenced from a commented-out call in EditProfileBloc.
  final String classesEndpoint = 'teacher/classes';
  final String titlesEndpoint = 'teacher/titles';

  EditProfileRepo({required this.networkClientRepository});

  Future<Either<Failure, void>> updateProfile({
    required String phone,
    required List<String> phones,
    required List<String> emails,
    // required List<String> classes,
    required String name,
    required String? title,
    int? gender,
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
        body: FormData.fromMap(
          {
            'name': name,
            'email': email,
            'phone': phone,
            'phones': phones.map((e) => ({"number": e})).toList(),
            'emails': emails.map((e) => ({"email": e})).toList(),
            // 'classes': classes.map((e) => ({"class_id": e})).toList(),
            if (gender != null) 'gender': gender,
            if (title != null) 'title_id': title,
            'cpf': cpf,
            'cpf_num': cpf,
            if (avatar != null)
              "avatar": await MultipartFile.fromFile(
                avatar.path,
                filename: avatar.path.split('/').last,
              ),
          },
        ),
      ),
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
        return (json['data'] as List)
            .map((e) => ClassModel.fromJson(e))
            .toList();
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
        return (json['data'] as List)
            .map((e) => TitleModel.fromJson(e))
            .toList();
      },
    );
  }
}
