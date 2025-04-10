import 'package:equatable/equatable.dart';
import 'package:escola/core/utils/valid_data.dart';

import 'add_form_model.dart';

class PeriodOfTimeModel extends FormModel {
  final List<PeriodOfTimeValueModel> values;
  final List<String> initial;
  final int? limit;
  final String hint;

  const PeriodOfTimeModel({
    required super.id,
    required super.title,
    required super.required,
    required super.dependency,
    required this.values,
    required this.hint,
    this.limit,
    this.initial = const [],
  }) : super(type: FormType.periodOfTime);

  factory PeriodOfTimeModel.fromJson(Map<String, dynamic> json) => PeriodOfTimeModel(
    id: validateString(json['id']?.toString()),
    title: validateString(json['title']?.toString()),
    dependency: validateDataModel(json['dependency'], (e) => FormDependencyModel.fromJson(e)),
    required: isSuccess(json['required']),
    values: validateDataList(json['values'], (e) => PeriodOfTimeValueModel.fromJson(e)),
    initial: validateList(json['initial']),
    hint: validateString(json['hint']?.toString()),
    limit: int.tryParse(json['limit']?.toString()??''),
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

class PeriodOfTimeValueModel extends Equatable {
  final String id;
  final String title;

  const PeriodOfTimeValueModel({
    required this.id,
    required this.title,
  });

  factory PeriodOfTimeValueModel.fromJson(Map<String, dynamic> json) => PeriodOfTimeValueModel(
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
