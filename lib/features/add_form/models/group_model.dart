import 'package:escola/core/utils/valid_data.dart';

import 'add_form_model.dart';

class GroupFormModel extends FormModel {
  final List<FormModel> items;

  const GroupFormModel({
    required super.id,
    required super.title,
    required this.items,
    required super.dependency,
    super.required = false,
  }) : super(type: FormType.group);

  factory GroupFormModel.fromJson(Map<String, dynamic> json) => GroupFormModel(
    id: validateString(json['id'].toString()),
    title: validateString(json['title'].toString()),
    dependency: validateDataModel(json['dependency'], (e) => FormDependencyModel.fromJson(e)),
    items: validateDataList(json['items'], (e) => FormModel.fromJson(e)),
  );

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'items': items.map((e) => e.toJson()).toList(),
  };

  @override
  List<Object?> get props => [
    ...super.props,
    items,
  ];
}