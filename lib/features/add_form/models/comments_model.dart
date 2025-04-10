import 'package:escola/core/utils/valid_data.dart';

import 'add_form_model.dart';

class CommentsModel extends FormModel {
  final String? label;

  const CommentsModel({
    required super.id,
    required super.title,
    required super.dependency,
    required super.required,
    this.label,
  }) : super(type: FormType.comments);

  factory CommentsModel.fromJson(Map<String, dynamic> json) => CommentsModel(
        id: validateString(json['id']?.toString()),
        title: validateString(json['title']?.toString()),
        dependency: validateDataModel(json['dependency'], (e) => FormDependencyModel.fromJson(e)),
        required: isSuccess(json['required']),
        label: validateString(json['label']?.toString()),
      );

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'label': label,
      };

  @override
  List<Object?> get props => [
        ...super.props,
        label,
      ];
}
