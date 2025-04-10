import 'package:escola/core/utils/valid_data.dart';

import 'add_form_model.dart';

class TextAreaModel extends FormModel {
  final String? hint;
  final String? initial;

  const TextAreaModel({
    required super.id,
    required super.title,
    required super.dependency,
    required super.required,
    this.hint,
    this.initial,
  }) : super(type: FormType.textArea);

  factory TextAreaModel.fromJson(Map<String, dynamic> json) => TextAreaModel(
        id: validateString(json['id']?.toString()),
        title: validateString(json['title']?.toString()),
        dependency: validateDataModel(json['dependency'], (e) => FormDependencyModel.fromJson(e)),
        required: isSuccess(json['required']),
        hint: validateString(json['hint']?.toString()),
        initial: validateString(json['initial']?.toString()),
      );

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'hint': hint,
        'initial': initial,
      };

  @override
  List<Object?> get props => [
        ...super.props,
        hint,
        initial,
      ];
}
