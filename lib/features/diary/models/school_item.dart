import 'package:equatable/equatable.dart';
import 'package:escola/core/models/user_model.dart';
import 'package:escola/features/diary/models/child_model.dart';

class SchoolItem extends Equatable {
  final int id;
  final String? name;
  final String? classRoom, avatar;
  final SchoolItemType type;
  final UserModel? parent;

  const SchoolItem(
      {required this.name,
      this.parent,
      required this.id,
      required this.classRoom,
      required this.avatar,
      required this.type});

  @override
  List<Object?> get props => [name, classRoom, avatar, type, id, parent];

  // fromJson
  factory SchoolItem.fromJson(Map<String, dynamic> json, SchoolItemType type) => SchoolItem(
        parent: json['parent'] == null ? null : UserModel.fromJson(json['parent'], UserType.parent),
        name: json['name'] as String,
        id: json['id'] as int,
        classRoom: json['class'] as String?,
        avatar: json['avatar'] as String?,
        type: type,
      );

  ChildModel getChildModel() {
    return ChildModel(
      id: id,
      name: name,
      avatar: avatar,
      age: null,
      classRoom: classRoom,
      parent: parent,
    );
  }
}

enum SchoolItemType { classType, childType, allChildType, allTeachersType, all, level, parentType, teacherType }

extension SchoolItemTypeExtension on SchoolItemType {
  String getString() {
    switch (this) {
      case SchoolItemType.classType:
        return 'class';
      case SchoolItemType.teacherType:
        return 'teacher';
      case SchoolItemType.parentType:
        return 'parent';
      case SchoolItemType.childType:
        return 'child';
      case SchoolItemType.allChildType:
        return 'allChild';
      case SchoolItemType.allTeachersType:
        return 'allTeachersType';
      case SchoolItemType.all:
        return 'all';
      case SchoolItemType.level:
        return 'level';
    }
  }
}

extension SchoolItemExtension on String {
  SchoolItemType getDiaryType() {
    switch (this) {
      case 'class':
        return SchoolItemType.classType;
      case 'teacher':
        return SchoolItemType.teacherType;
      case 'parent':
        return SchoolItemType.parentType;
      case 'child':
        return SchoolItemType.childType;
      case 'allChild':
        return SchoolItemType.allChildType;
      case 'allTeachersType':
        return SchoolItemType.allTeachersType;
      case 'all':
        return SchoolItemType.all;
      case 'level':
        return SchoolItemType.level;
      default:
        return SchoolItemType.childType;
    }
  }
}
