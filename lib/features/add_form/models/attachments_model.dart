import 'package:escola/core/utils/valid_data.dart';

import 'add_form_model.dart';

class AttachmentsModel extends FormModel {
  final String? hint;
  final String? label;
  final int? limit;

  const AttachmentsModel({
    required super.title,
    required super.id,
    required super.dependency,
    required super.required,
    this.hint,
    this.label,
    this.limit,
  }) : super(type: FormType.attachment);

  factory AttachmentsModel.fromJson(Map<String, dynamic> json) => AttachmentsModel(
        id: validateString(json['id']?.toString()),
        title: validateString(json['title']?.toString()),
        dependency: validateDataModel(json['dependency'], (e) => FormDependencyModel.fromJson(e)),
        required: isSuccess(json['required']),
        hint: validateString(json['hint']?.toString()),
        label: validateString(json['label']?.toString()),
        limit: int.tryParse(json['limit'].toString()),
      );

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'hint': hint,
        'label': label,
        'limit': limit,
      };

  @override
  List<Object?> get props => [
        ...super.props,
        hint,
        label,
        limit,
      ];
}
