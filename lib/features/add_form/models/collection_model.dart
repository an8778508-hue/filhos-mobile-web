import 'package:escola/core/utils/valid_data.dart';

import 'add_form_model.dart';

class CollectionFormModel extends FormModel {
  final List<FormModel> items;

  const CollectionFormModel({
    required super.id,
    required super.title,
    required super.dependency,
    super.required = false,
    required this.items,
  }) : super(type: FormType.collection);

  factory CollectionFormModel.fromJson(Map<String, dynamic> json) => CollectionFormModel(
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
