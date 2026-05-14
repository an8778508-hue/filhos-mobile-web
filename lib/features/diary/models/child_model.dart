import 'package:equatable/equatable.dart';
import 'package:escola/core/models/user_model.dart';
import 'package:escola/core/utils/valid_data.dart';

class ChildModel extends Equatable {
  final int id;
  final String? name, classRoom, age, avatar;
  final UserModel? parent;

  const ChildModel(
      {required this.id,
      required this.name,
      required this.age,
      required this.classRoom,
      required this.parent,
      required this.avatar});

  @override
  List<Object?> get props => [id, name, age, avatar, classRoom, parent];

  // from Json
  factory ChildModel.fromJson(Map<String, dynamic> json) {
    return ChildModel(
      parent: json['parent'] == null
          ? null
          : UserModel.fromJson(json['parent'], UserType.parent),
      id: validateInt(json['id']),
      name: validateString(json['name']),
      age: validateString(json['age']),
      avatar: validateString(json['avatar']),
      classRoom: validateString(json['class']),
    );
  }

  // toJson
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'age': age,
        'avatar': avatar,
        'class': classRoom,
        'parent': parent?.toJson()
      };

  // copy with
  ChildModel copyWith({
    int? id,
    String? name,
    String? age,
    String? avatar,
    String? classRoom,
    UserModel? parent,
  }) {
    return ChildModel(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      avatar: avatar ?? this.avatar,
      classRoom: classRoom ?? this.classRoom,
      parent: parent ?? this.parent,
    );
  }
}
