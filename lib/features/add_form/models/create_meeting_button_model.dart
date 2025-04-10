import 'package:escola/core/utils/valid_data.dart';

import 'add_form_model.dart';

class CreateMeetingButtonModel extends FormModel {
  final String? label;
  final String? hint;

  const CreateMeetingButtonModel({
    required super.id,
    required super.title,
    required super.required,
    required super.dependency,
    this.label,
    this.hint,
  }) : super(type: FormType.createMeetingButton);

  factory CreateMeetingButtonModel.fromJson(Map<String, dynamic> json) => CreateMeetingButtonModel(
        id: validateString(json['id']?.toString()),
        title: validateString(json['title']?.toString()),
        dependency: validateDataModel(json['dependency'], (e) => FormDependencyModel.fromJson(e)),
        required: isSuccess(json['required']),
        label: validateString(json['label']?.toString()),
        hint: validateString(json['hint']?.toString()),
      );

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'label': label,
        'hint': hint,
      };

  @override
  List<Object?> get props => [
        ...super.props,
        label,
        hint,
      ];
}
