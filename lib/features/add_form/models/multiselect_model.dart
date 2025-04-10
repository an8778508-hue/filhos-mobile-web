import 'package:equatable/equatable.dart';
import 'package:escola/core/utils/valid_data.dart';

import 'add_form_model.dart';

class MultiSelectModel extends FormModel {
  final List<MultiSelectValueModel> values;
  final List<String> initial;
  final int? limit;
  final String hint;

  const MultiSelectModel({
    required super.id,
    required super.title,
    required this.values,
    required this.hint,
    required super.required,
    required super.dependency,
    this.limit,
    this.initial = const [],
  }) : super(type: FormType.multiselect);

  factory MultiSelectModel.fromJson(Map<String, dynamic> json) => MultiSelectModel(
        id: validateString(json['id']?.toString()),
        title: validateString(json['title']?.toString()),
        dependency: validateDataModel(json['dependency'], (e) => FormDependencyModel.fromJson(e)),
        required: isSuccess(json['required']),
        values: validateDataList(json['values'], (e) => MultiSelectValueModel.fromJson(e)),
        initial: validateList(json['initial']),
        hint: validateString(json['hint']?.toString()),
        limit: int.tryParse(json['limit']?.toString() ?? ''),
      );

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'values': values.map((e) => e.toJson()).toList(),
        'initial': initial,
        'hint': hint,
        'limit': limit,
      };

  @override
  List<Object?> get props => [
        ...super.props,
        values,
        initial,
        hint,
        limit,
      ];
}

class MultiSelectValueModel extends Equatable {
  final String id;
  final String title;

  const MultiSelectValueModel({
    required this.id,
    required this.title,
  });

  factory MultiSelectValueModel.fromJson(Map<String, dynamic> json) => MultiSelectValueModel(
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
