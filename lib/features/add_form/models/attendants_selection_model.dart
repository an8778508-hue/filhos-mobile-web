import 'package:escola/core/utils/valid_data.dart';

import 'add_form_model.dart';

class AttendantsSelectionModel extends FormModel {
  final String? label;

  const AttendantsSelectionModel({
    required super.title,
    required super.id,
    required super.dependency,
    super.required = true,
    this.label,
  }) : super(type: FormType.attendantsSelection);

  factory AttendantsSelectionModel.fromJson(Map<String, dynamic> json) => AttendantsSelectionModel(
        id: validateString(json['id']?.toString()),
        title: validateString(json['title']?.toString()),
        dependency: validateDataModel(json['dependency'], (e) => FormDependencyModel.fromJson(e)),
        label: validateString(json['label']?.toString()),
      );

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'label': label,
      };

  @override
  List<Object?> get props => [
        ...super.props,
        label,
      ];
}
