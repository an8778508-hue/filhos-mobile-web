import 'package:escola/features/diary/models/main_category.dart';
import 'package:escola/features/diary/models/questions_models/question.dart';

class DurationQuestion extends Question {
  final String? duration;
  final MainCategory? mainCategory;
  final String? icon_value;

  const DurationQuestion({
    required int id,
    required String? label,
    String? subtitle,
    required this.duration,
    this.mainCategory,
    this.icon_value,
  }) : super(
            id: id,
            type: QuestionType.duration,
            title: label,
            subtitle: subtitle,
            // mainCategory: mainCategory,
      // icon_value: icon_value,
            value: duration);

  @override
  List<Object?> get props => [id, type, title, subtitle, icon_value, duration];

  // toJson
  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': 'duration',
        'label': title,
        'value': duration,
        'icon_value': icon_value,
      };
}
