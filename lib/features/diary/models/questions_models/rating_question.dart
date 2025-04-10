import 'package:escola/features/diary/models/main_category.dart';
import 'package:escola/features/diary/models/questions_models/question.dart';

class RatingQuestion extends Question {
  final int? rating;
  final MainCategory? mainCategory;
  final String? icon_value;

  const RatingQuestion({
    required int id,
    String? label,
    String? subtitle,
    required this.rating,
    this.mainCategory,
    this.icon_value,
  }) : super(
          id: id,
          type: QuestionType.rating,
          // mainCategory: mainCategory,
          // icon_value: icon_value,
          title: label,
          value: rating,
        );

  @override
  List<Object?> get props => [id, type, title, subtitle, icon_value, rating];

  // toJson
  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': 'rating',
        'label': title,
        'value': rating,
        'icon_value': icon_value,
      };
}
