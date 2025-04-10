import 'package:equatable/equatable.dart';

class SearchForFilterModel extends Equatable {
  final int id;
  final String name;
  final String? classRoom, avatar;
  final SearchForFilterModelType type;

  const SearchForFilterModel(
      {required this.name,
      required this.id,
      required this.classRoom,
      required this.avatar,
      required this.type});

  @override
  List<Object?> get props => [name, classRoom, avatar, type, id];

  // fromJson
  factory SearchForFilterModel.fromJson(Map<String, dynamic> json, SearchForFilterModelType type) =>
      SearchForFilterModel(
        name: json['name'] as String,
        id: json['id'] as int,
        classRoom: json['class'] as String?,
        avatar: json['avatar'] as String?,
        type: type,
      );
}

enum SearchForFilterModelType { childOrParent, classType, teacher, level }

extension SearchForFilterModelTypeExtension on SearchForFilterModelType {
  String getString() {
    switch (this) {
      case SearchForFilterModelType.childOrParent:
        return 'childOrParent';
      case SearchForFilterModelType.teacher:
        return 'teacher';
      case SearchForFilterModelType.level:
        return 'level';case SearchForFilterModelType.classType:
        return 'classType';
    }
  }
}

extension SearchForFilterModelExtension on String {
  SearchForFilterModelType getDiaryType() {
    switch (this) {
      case 'childOrParent':
        return SearchForFilterModelType.childOrParent;
      case 'teacher':
        return SearchForFilterModelType.teacher;
      case 'level':
        return SearchForFilterModelType.level;      case 'classType':
        return SearchForFilterModelType.classType;
      default:
        return SearchForFilterModelType.childOrParent;
    }
  }
}
