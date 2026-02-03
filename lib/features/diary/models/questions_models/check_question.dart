import 'package:escola/features/diary/models/main_category.dart';
import 'package:escola/features/diary/models/questions_models/question.dart';

class CheckQuestion extends Question {
  @override
  final String? value;
  final MainCategory? mainCategory;
  final String? icon_value;

  const CheckQuestion({
    required super.id,
    required super.title,
    super.subtitle,
    required this.value,
    this.mainCategory,
    this.icon_value,
  }) : super(
          type: QuestionType.checkbox,
          // mainCategory: mainCategory,
          // icon_value: icon_value,
          value: value,
        );

  @override
  List<Object?> get props => [id, type, title, subtitle, icon_value, value];

  copyWith({
    int? id,
    String? title,
    String? subtitle,
    String? value,
    String? icon_value,
    MainCategory? mainCategory,
  }) {
    return CheckQuestion(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      value: value ?? this.value,
      icon_value: icon_value ?? this.icon_value,
      mainCategory: mainCategory ?? this.mainCategory,
    );
  }

  // toJson
  @override
  Map<String, dynamic> toJson() {
    print('CheckQuestion.toJson $icon_value');
    return {
      'id': id,
      'type': 'checkbox',
      'title': title,
      'icon_value': icon_value,
      'value': value,
    };
  }
}
