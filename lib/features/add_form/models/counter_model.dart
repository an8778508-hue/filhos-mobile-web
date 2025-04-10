import 'package:escola/core/utils/valid_data.dart';

import 'add_form_model.dart';

class CounterModel extends FormModel {
  final double min;
  final double max;
  final double step;
  final double initial;

  const CounterModel({
    required super.id,
    required super.title,
    required super.required,
    required super.dependency,
    this.min = 0.0,
    this.max = 10,
    this.step = 0.25,
    this.initial = 1.0,
  }) : super(type: FormType.counter);

  factory CounterModel.fromJson(Map<String, dynamic> json) => CounterModel(
        id: validateString(json['id']?.toString()),
        title: validateString(json['title']?.toString()),
        dependency: validateDataModel(json['dependency'], (e) => FormDependencyModel.fromJson(e)),
        required: isSuccess(json['required']),
        min: convertToDouble(json['min']),
        max: convertToDouble(json['max']),
        step: convertToDouble(json['step']),
        initial: convertToDouble(json['initial']),
      );

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'min': min,
        'max': max,
        'step': step,
        'initial': initial,
      };

  @override
  List<Object?> get props => [
        ...super.props,
        min,
        max,
        step,
        initial,
      ];
}
