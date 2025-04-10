import 'package:equatable/equatable.dart';
import 'package:escola/core/models/user_model.dart';
import 'package:escola/core/utils/valid_data.dart';

class ChildDetailsModel extends Equatable {
  final int? id;
  final String? name, code, grade, age, gender, birthday, series, avatar;
  final UserModel? responsible;
  final UserModel? enroll_parent;

  const ChildDetailsModel(
      {required this.id,
      required this.responsible,
      required this.birthday,
      required this.gender,
      required this.series,
      required this.name,
      required this.enroll_parent,
      required this.code,
      required this.age,
      required this.grade,
      required this.avatar});

  @override
  List<Object?> get props => [id, name, age, avatar, grade];

  // from Json
  factory ChildDetailsModel.fromJson(Map<String, dynamic> json) {
    return ChildDetailsModel(
      id: validateInt(json['id']),
      series: validateString(json['series']),
      name: validateString(json['name']),
      birthday: validateString(json['birthday']),
      code: validateString(json['code']),
      age: validateString(json['age']),
      gender: validateString(json['gender']),
      avatar: validateString(json['avatar']),
      grade: validateString(json['grade']),
      responsible: UserModel.fromJson(validateMap(json['responsible'])),
      enroll_parent: UserModel.fromJson(validateMap(json['enroll_parent'])),
    );
  }

  // toJson
  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'age': age,
        'gender': gender,
        'birthday': birthday,
        'avatar': avatar,
        'grade': grade,
        'responsible': responsible?.toJson(),
        'enroll_parent': enroll_parent?.toJson(),
      };
}
