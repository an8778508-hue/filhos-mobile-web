import 'package:escola/core/utils/date_time_utils.dart';
import 'package:escola/core/utils/valid_data.dart';

import 'add_form_model.dart';

class DatePickerModel extends FormModel {
  final String? hint;
  final DateTime? min;
  final DateTime? max;
  final DateTime? initial;

  const DatePickerModel({
    required super.id,
    required super.title,
    required super.required,
    required super.dependency,
    this.hint,
    this.min,
    this.max,
    this.initial,
  }) : super(type: FormType.datePicker);

  factory DatePickerModel.fromJson(Map<String, dynamic> json) => DatePickerModel(
        id: validateString(json['id']?.toString()),
        title: validateString(json['title']?.toString()),
        dependency: validateDataModel(json['dependency'], (e) => FormDependencyModel.fromJson(e)),
        required: isSuccess(json['required']),
        hint: validateString(json['hint']?.toString()),
        min: parseDateTime(json['min']?.toString()),
        max: parseDateTime(json['max']?.toString()),
        initial: parseDateTime(json['initial']?.toString()),
      );

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'min': formatDateTime(min),
        'max': formatDateTime(max),
        'initial': formatDateTime(initial),
        'hint': hint,
      };

  @override
  List<Object?> get props => [
        ...super.props,
        min,
        max,
        hint,
        initial,
      ];
}
