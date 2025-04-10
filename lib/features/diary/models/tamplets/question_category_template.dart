import 'package:equatable/equatable.dart';
import 'package:escola/features/diary/models/tamplets/question_template.dart';

class QuestionCategoryTemplate extends Equatable {
  final int id;
  final String? title, icon, type, value, statusType;
  final List<QuestionTemplate> questionTamplets;

  const QuestionCategoryTemplate(
      {required this.title,
      required this.id,
      required this.icon,
      required this.type,
      required this.statusType,
      required this.value,
      required this.questionTamplets});

  @override
  List<Object?> get props => [title, icon, questionTamplets, type, value];

  // from Json
  factory QuestionCategoryTemplate.fromJson(Map<String, dynamic> json) {
    return QuestionCategoryTemplate(
      id: json['id'],
      title: json['name'],
      statusType: json['attendance_type'],
      icon: json['icon'],
      type: json['type'],
      value: json['attendance_type'],
      questionTamplets:json['questions'] == null?[] :List<QuestionTemplate>.from(
        json['questions'].map(
          (x) => QuestionTemplate.fromJson(x, json['id']),
        ),
      ),
    );
  }

  // copy with
  QuestionCategoryTemplate copyWith({
    String? title,
    String? icon,
    String? type,
    String? statusType,
    String? value,
    List<QuestionTemplate>? questionTamplets,
    int? id,
  }) {
    return QuestionCategoryTemplate(
      title: title ?? this.title,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      statusType: statusType ?? this.statusType,
      value: value ?? this.value,
      questionTamplets: questionTamplets ?? this.questionTamplets,
      id: id ?? this.id,
    );
  }
}
