import 'package:equatable/equatable.dart';
import 'package:escola/features/diary/models/main_category.dart';
import 'package:escola/features/diary/models/questions_models/question.dart';

class SelectQuestion extends Question {
  final List<SelectItem> items;
  final MainCategory? mainCategory;
  final String? icon_value;

  const SelectQuestion({
    required int id,
    String? label,
    String? subtitle,
    required this.items,
    this.mainCategory,
    this.icon_value,
  }) : super(
          id: id,
          type: QuestionType.select,
          title: label,
          subtitle: subtitle,
          // mainCategory: mainCategory,
          // icon_value: icon_value,
          value: items,
        );

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': 'select',
        'label': title,
        'icon_value': icon_value,
        'value': items.map((e) => e.toJson()).toList(),
      };

  @override
  List<Object?> get props => [id, type, title, subtitle, icon_value, items];
}

class SelectItem extends Equatable {
  final String key;
  final String? value, icon, icon_value;

  const SelectItem({
    required this.key,
    required this.value,
    required this.icon,
    required this.icon_value,
  });

  //from Json
  factory SelectItem.fromJson(Map<String, dynamic> json) {
    return SelectItem(
      key: json['key'],
      value: json['value'],
      icon: json['icon'],
      icon_value: json['icon_value'].toString(),
    );
  }

  //toJson
  Map<String, dynamic> toJson() => {
        'key': key,
        'value': value,
        'icon': icon,
        'icon_value': icon_value,
      };

  @override
  List<Object?> get props => [key, value, icon];
}
