import 'package:escola/features/diary/models/main_category.dart';
import 'package:escola/features/diary/models/questions_models/question.dart';

class NumberQuestion extends Question {
  final int? number;
  final MainCategory? mainCategory;
  final String? icon_value;

  const NumberQuestion({
    required int id,
    String? label,
    String? subtitle,
    required this.number,
    this.mainCategory,
    this.icon_value,
  }) : super(
          id: id,
          type: QuestionType.number,
          title: label,
          // mainCategory: mainCategory,
          subtitle: subtitle,
          value: number,
        );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': 'number',
        'label': title,
        'value': number,
        'icon_value': icon_value,
      };

  @override
  List<Object?> get props => [id, type, title, subtitle, icon_value, number];
}
