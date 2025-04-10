import 'package:equatable/equatable.dart';
import 'package:escola/core/utils/valid_data.dart';

import 'add_form_model.dart';

class DropDownModel extends FormModel {
  final List<DropDownValueModel> values;
  final String? initial;
  final String hint;

  const DropDownModel({
    required super.id,
    required super.title,
    required this.values,
    required this.hint,
    required super.required,
    required super.dependency,
    this.initial,
  }) : super(type: FormType.dropdown);

  factory DropDownModel.fromJson(Map<String, dynamic> json) => DropDownModel(
        id: validateString(json['id']?.toString()),
        title: validateString(json['title']?.toString()),
        dependency: validateDataModel(json['dependency'], (e) => FormDependencyModel.fromJson(e)),
        required: isSuccess(json['required']),
        values: validateDataList(json['values'], (e) => DropDownValueModel.fromJson(e)),
        initial: validateString(json['initial']?.toString()),
        hint: validateString(json['hint']?.toString()),
      );

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'values': values.map((e) => e.toJson()).toList(),
        'initial': initial,
        'hint': hint,
      };

  @override
  List<Object?> get props => [
        ...super.props,
        values,
        initial,
        hint,
      ];
}

class DropDownValueModel extends Equatable {
  final String id;
  final String title;

  const DropDownValueModel({
    required this.id,
    required this.title,
  });

  factory DropDownValueModel.fromJson(Map<String, dynamic> json) => DropDownValueModel(
        id: validateString(json['id']?.toString()),
        title: validateString(json['title']?.toString(), validateString(json['name']?.toString())),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
      };

  @override
  List<Object?> get props => [
        id,
        title,
      ];
}
