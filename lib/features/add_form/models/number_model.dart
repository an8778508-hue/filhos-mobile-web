import 'package:escola/core/utils/valid_data.dart';

import 'add_form_model.dart';

class NumberModel extends FormModel {
  final String? hint;
  final String? initial;

  const NumberModel({
    required super.id,
    required super.title,
    required super.required,
    required super.dependency,
    this.hint,
    this.initial,
  }) : super(type: FormType.number);

  factory NumberModel.fromJson(Map<String, dynamic> json) => NumberModel(
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
