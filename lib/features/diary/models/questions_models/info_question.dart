import 'package:escola/features/diary/models/main_category.dart';
import 'package:escola/features/diary/models/questions_models/question.dart';

class InfoQuestion extends Question {
  final String? info;
  final MainCategory? mainCategory;
  final String? icon_value;

  const InfoQuestion({
    required int id,
    String? label,
    String? subtitle,
    required this.info,
    this.mainCategory,
    this.icon_value,
  }) : super(
            id: id,
            type: QuestionType.textarea,
            title: label,
            subtitle: subtitle,
            // mainCategory: mainCategory,
      // icon_value: icon_value,
            value: info);

  @override
  List<Object?> get props => [id, type, title, subtitle, info];

// toJson
  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': 'textarea',
        'label': title,
        'value': info,
        'icon_value': icon_value,
      };
}
