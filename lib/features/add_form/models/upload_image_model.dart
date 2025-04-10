import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/add_form/models/params.dart';

import 'add_form_model.dart';

class UploadImageModel extends FormModel {
  final String? hint;
  final String? label;
  final int? limit;
  final List<UploadFileParam>? initial;

  const UploadImageModel({
    required super.title,
    required super.id,
    required super.dependency,
    required super.required,
    this.hint,
    this.label,
    this.limit,
    this.initial,
  }) : super(type: FormType.uploadImage);

  factory UploadImageModel.fromJson(Map<String, dynamic> json) => UploadImageModel(
        id: validateString(json['id']?.toString()),
        title: validateString(json['title']?.toString()),
        dependency: validateDataModel(json['dependency'], (e) => FormDependencyModel.fromJson(e)),
        required: isSuccess(json['required']),
        hint: validateString(json['hint']?.toString()),
        label: validateString(json['label']?.toString()),
        limit: int.tryParse(json['limit'].toString()),
        initial: json['initial'] == null
            ? null
            : List<UploadFileParam>.from(
                (json['initial'] is String) ? [UploadFileParam(url: json['initial'])] : json['initial']),
      );

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'hint': hint,
        'label': label,
        'limit': limit,
        'initial': initial,
      };

  @override
  List<Object?> get props => [
        ...super.props,
        hint,
        label,
        limit,
        initial,
      ];
}
