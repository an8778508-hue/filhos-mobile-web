import 'package:escola/core/utils/valid_data.dart';

class OnBoardModel {
  const OnBoardModel(this.json);

  final Map<String, dynamic> json;

  String get title => validateString(json['title']);

  String get subTitle => validateString(json['subtitle']);

  String get image => validateString(json['image']);

  // fromJson
  OnBoardModel.fromJson(Map<String, dynamic> json) : this(json);
}
