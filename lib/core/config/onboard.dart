import 'package:escola/core/utils/valid_data.dart';

class OnBoardModel {
  const OnBoardModel(this.json);

  final Map<String, dynamic> json;

  String get title => validateString(json['title']);

  // The config API sends the field as `subtitle`; older payloads used
  // `description`. Prefer `subtitle`, fall back to `description`.
  String get subTitle =>
      validateString(json['subtitle'] ?? json['description']);

  String get image => validateString(json['image']);

  // fromJson
  OnBoardModel.fromJson(Map<String, dynamic> json) : this(json);
}
