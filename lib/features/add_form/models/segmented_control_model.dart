import 'package:equatable/equatable.dart';
import 'package:escola/core/utils/valid_data.dart';

import 'add_form_model.dart';

class SegmentedControlModel extends FormModel {
  final List<SegmentedControlValueModel> values;
  final String? initial;

  const SegmentedControlModel({
    required super.id,
    required super.title,
    required super.dependency,
    required super.required,
    required this.values,
    this.initial,
  }) : super(type: FormType.segmented);

  factory SegmentedControlModel.fromJson(Map<String, dynamic> json) => SegmentedControlModel(
        id: validateString(json['id']?.toString()),
        title: validateString(json['title']?.toString()),
        dependency: validateDataModel(json['dependency'], (e) => FormDependencyModel.fromJson(e)),
        required: isSuccess(json['required']),
        values: validateDataList(json['values'], (e) => SegmentedControlValueModel.fromJson(e)),
        initial: validateString(json['initial']?.toString()),
      );

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'values': values.map((e) => e.toJson()).toList(),
        'initial': initial,
      };

  @override
  List<Object?> get props => [
        ...super.props,
        values,
        initial,
      ];
}

class SegmentedControlValueModel extends Equatable {
  final String id;
  final String title;

  const SegmentedControlValueModel({
    required this.id,
    required this.title,
  });

  factory SegmentedControlValueModel.fromJson(Map<String, dynamic> json) => SegmentedControlValueModel(
        id: validateString(json['id']?.toString()),
        title: validateString(json['title']?.toString()),
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
