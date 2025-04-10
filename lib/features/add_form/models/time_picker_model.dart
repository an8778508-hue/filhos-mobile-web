import 'package:escola/core/utils/date_time_utils.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:flutter/material.dart';

import 'add_form_model.dart';

class TimePickerModel extends FormModel {
  final String? hint;
  final TimeOfDay? initial;

  const TimePickerModel({
    required super.id,
    required super.title,
    required super.dependency,
    required super.required,
    this.hint,
    this.initial,
  }) : super(type: FormType.timePicker);

  factory TimePickerModel.fromJson(Map<String, dynamic> json) => TimePickerModel(
        id: validateString(json['id']?.toString()),
        title: validateString(json['title']?.toString()),
        dependency: validateDataModel(json['dependency'], (e) => FormDependencyModel.fromJson(e)),
        required: isSuccess(json['required']),
        hint: validateString(json['hint']?.toString()),
        initial: parseTime(json['initial']?.toString()),
      );

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'hint': hint,
        'initial': formatTime(initial),
      };

  @override
  List<Object?> get props => [
        ...super.props,
        hint,
        initial,
      ];
}
