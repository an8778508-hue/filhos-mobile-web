import 'package:collection/collection.dart';
import 'package:escola/core/utils/funuctions/global_functions.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/settings/edit_profile/models/class_model.dart';
import 'package:escola/features/settings/edit_profile/models/email_model.dart';
import 'package:escola/features/settings/edit_profile/models/phone_model.dart';
import 'package:escola/features/settings/edit_profile/models/title_model.dart';

class UserModel {
  final String id;
  final String? name;
  final String phone;
  final String email;
  final String? cpf;
  final String? genderId;
  final String? accessToken;
  final bool isApproval;
  final String? image;
  final String? code;
  final String countryCode;
  final String? classRoom;
  final UserType? type;
  final TitleModel? title;
  final List<ClassModel> classes;
  final List<EmailModel> emails;
  final List<PhoneModel> phones;
  final int? schoolId;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.classRoom,
    required this.email,
    this.cpf,
    required this.accessToken,
    required this.isApproval,
    required this.image,
    required this.countryCode,
    this.code,
    this.schoolId,
    this.genderId,
    this.type,
    this.title,
    this.classes = const [],
    this.emails = const [],
    this.phones = const [],
  });

  copyWith({
    String? id,
    String? phone,
    String? email,
    String? cpf,
    String? accessToken,
    String? role,
    bool? isApproval,
    String? image,
    String? countryCode,
    String? genderId,
    String? classRoom,
    String? code,
    String? name,
    UserType? type,
    TitleModel? title,
    List<ClassModel>? classes,
    List<EmailModel>? emails,
    List<PhoneModel>? phones,
    int? schoolId,
  }) {
    return UserModel(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      cpf: cpf ?? this.cpf,
      accessToken: accessToken ?? this.accessToken,
      isApproval: isApproval ?? this.isApproval,
      image: image ?? this.image,
      countryCode: countryCode ?? this.countryCode,
      genderId: genderId ?? this.genderId,
      classRoom: classRoom ?? this.classRoom,
      code: code ?? this.code,
      name: name ?? this.name,
      type: type ?? this.type,
      title: title ?? this.title,
      classes: classes ?? this.classes,
      emails: emails ?? this.emails,
      phones: phones ?? this.phones,
      schoolId: schoolId ?? this.schoolId,
    );
  }

  // toJson
  Map<String, dynamic> toJson([String? oldToken]) {
    print('UserModel.toJson oldToken $oldToken');
    print('UserModel.toJson accessToken $accessToken');
    print('UserModel.toJson validString ${validString(accessToken)}');
    return {
      "id": id,
      "name": name,
      "phone": phone,
      "email": email,
      "cpf": cpf,
      "access_token": validString(accessToken) ? accessToken : oldToken,
      "gender": genderId,
      "class": classRoom,
      "classes": classes.map((e) => e.toJson()).toList(),
      "emails": emails.map((e) => e.toJson()).toList(),
      "phones": phones.map((e) => e.toJson()).toList(),
      "is_approval": isApproval,
      "avatar": image,
      "code": code,
      "country_code": countryCode,
      "role": type?.toTypeString(),
      "school_id": schoolId,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json, [UserType? type]) {
    // print('UserModel.fromJson ${json}');
    // print('UserModel.fromJson ${json['cpf_num']}');
    return UserModel(
      id: validateString(json['id']?.toString()),
      schoolId: json['school_id'],
      name: validateString(json['name']?.toString()),
      phone: validateString(json['phone']?.toString()),
      genderId: validateString(json['gender']?.toString()),
      classRoom: validateString(json['class']?.toString()),
      email: validateString(json['email']?.toString()),
      cpf: validateString((json['cpf']??json['cpf_num'])?.toString()),
      accessToken: validateString(json['access_token']?.toString()),
      isApproval: isSuccess(json['is_approval']),
      image: validateString(json['avatar']?.toString()),
      code: validateString(json['code']?.toString()),
      countryCode: validateString(json['country_code']?.toString()),
      type: json['role'].toString().toUserType(),
      title: json['title'] == null ? null : TitleModel.fromJson(json['title']),
      classes: json['classes'] == [null] ? [] : validateDataList(json['classes'], (e) => ClassModel.fromJson(e)),
      emails: json['emails'] == [null] ? [] : validateDataList(json['emails'], (e) => EmailModel.fromJson(e)),
      phones: json['phones'] == [null] ? [] : validateDataList(json['phones'], (e) => PhoneModel.fromJson(e)),
    );
  }
}

enum UserType { parent, professor }

extension UserTypeExtension on UserType? {
  String toTypeString() {
    switch (this) {
      case UserType.parent:
        return "parent";
      case UserType.professor:
        return "teacher";
      default:
        return "parent";
    }
  }
}

extension StringToUserType on String? {
  UserType toUserType() {
    switch (this) {
      case '3':
        return UserType.parent;
      case '5':
        return UserType.professor;
      case 'parent':
        return UserType.parent;
      case 'professor':
        return UserType.professor;
      case 'UserType.parent':
        return UserType.parent;
      case 'UserType.professor':
        return UserType.professor;
      case 'teacher':
        return UserType.professor;
      default:
        return UserType.parent;
    }
  }
}

extension UserModelX on UserModel {
  bool completedProfile() {
    if (type == null) return false;
    switch (type!) {
      case UserType.parent:
        return _checkParentProfile();
      case UserType.professor:
        return _checkProfessorProfile();
    }
  }

  double getPercentage() {
    if (type == null) return 50;
    switch (type!) {
      case UserType.parent:
        int percentage = 0;
        final List<String?> parentFields = [
          name,
          phone,
          if (validString(countryCode) && isBrazilCountry(countryCode)) cpf,
          image,
        ];
        for (var element in parentFields) {
          if (validString(element)) {
            percentage++;
          }
        }
        return (percentage / parentFields.length) * 100;
      case UserType.professor:
        int percentage = 0;
        final List<String?> parentFields = [
          name,
          phone,
          email,
          title?.name,
          classes.firstWhereOrNull((element) => element.name.isNotEmpty)?.name,
          if (validString(countryCode) && isBrazilCountry(countryCode)) cpf,
          image,
        ];
        for (var element in parentFields) {
          if (validString(element)) {
            percentage++;
          }
        }
        return (percentage / parentFields.length) * 100;
    }
  }

  bool _checkParentProfile() {
    return !_getParentList().any((e) => !validString(e));
  }

  bool _checkProfessorProfile() {
    return !_getProfessorList().any((e) => !validString(e));
  }

  List<String?> _getParentList() {
    return [
      name,
      phone,
      email,
      if (validString(countryCode) && isBrazilCountry(countryCode)) cpf,
      image,
    ];
  }

  List<String?> _getProfessorList() {
    return [
      name,
      phone,
      email,
      title?.name,
      // classes.firstWhereOrNull((element) => element.name.isNotEmpty)?.name,
      if (validString(countryCode) && isBrazilCountry(countryCode)) cpf,
      image,
    ];
  }
}
