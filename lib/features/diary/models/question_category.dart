import 'package:equatable/equatable.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/diary/models/category_menu_item.dart';
import 'package:escola/features/diary/models/questions_models/question.dart';

class QuestionCategory extends Equatable {
  final int? id;
  final String? title, icon, type, value, statusType;
  final String? count_love, count_wow, count_sad, count_angry, count_like, count_haha, totalCount;

  final List<Question>? questions;
  final List<String>? answer;
  final Question? question;
  final String? icon_value;

  static String foodType = 'food';

  const QuestionCategory({
    required this.title,
    required this.icon,
    required this.id,
    required this.statusType,
    required this.type,
    required this.value,
    required this.questions,
    this.question,
    this.count_love,
    this.count_wow,
    this.count_sad,
    this.count_angry,
    this.count_like,
    this.count_haha,
    this.totalCount,
    this.answer,
    this.icon_value,
  });

  @override
  List<Object?> get props => [title, icon, questions, type, icon_value, value];

  // from Json
  factory QuestionCategory.fromJson(Map<String, dynamic> json) {
    final categoryData = json['category'];
    final questionAnswers = json['answers'] ?? [];
    final List<String>? answersOfQuestions = json['answer'] == null
        ? null
        : List<String>.from((json['answer'] is String) ? [json['answer']] : json['answer']);
    final String countLove = validateString(json['count_love'].toString());
    final String countWow = validateString(json['count_wow'].toString());
    final String countSad = validateString(json['count_sad'].toString());
    final String countAngry = validateString(json['count_angry'].toString());
    final String countLike = validateString(json['count_like'].toString());
    final String countHaha = validateString(json['count_haha'].toString());
    final totalCount = (int.tryParse(countLove) ?? 0) +
        (int.tryParse(countWow) ?? 0) +
        (int.tryParse(countSad) ?? 0) +
        (int.tryParse(countAngry) ?? 0) +
        (int.tryParse(countLike) ?? 0) +
        (int.tryParse(countHaha) ?? 0);
    String? iconValue;
    final metadata = json['metadata'];
    if (metadata != null && metadata is List && metadata.isNotEmpty) {
      final list = metadata[0]? ['value' ] ;
      String? icon ;
      if(list != null && list is List && list.isNotEmpty){
        icon  = list[0]['icon_value'];

      }
      iconValue = metadata[0]['icon_value']??icon ;
    }

    return QuestionCategory(
      statusType: categoryData?['attendance_type'],
      id: categoryData?['id'],
      title: categoryData?['name'],
      icon: categoryData?['icon'],
      type: categoryData?['type'],
      count_love: countLove,
      count_wow: countWow,
      count_sad: countSad,
      count_angry: countAngry,
      count_like: countLike,
      count_haha: countHaha,
      icon_value: iconValue,
      totalCount: totalCount.toString(),
      value: categoryData?['attendance_type'],
      answer: answersOfQuestions,
      questions: List<Question>.from(questionAnswers.map((x) => Question.fromJson(x))),
      question: Question.fromJson(json['question'] ?? {}),
    );
  }

  // to Json
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (validString(type)) 'type': type,
      if (validString(value)) 'attendance_type': value,
      if (question != null) 'question': question!.toJson(),
      'questions': questions?.map((x) => x.toJson()).toList(),
    };
  }

  // copyWith
  QuestionCategory copyWith({
    String? title,
    String? icon,
    String? menuIcon,
    String? type,
    String? statusType,
    String? value,
    String? count_love,
    String? count_wow,
    String? count_sad,
    String? count_angry,
    String? count_like,
    String? count_haha,
    String? totalCount,
    List<Question>? questions,
    Question? question,
    int? id,
    List<Menu>? menus,
  }) {
    return QuestionCategory(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      questions: questions ?? this.questions,
      type: type ?? this.type,
      count_love: count_love ?? this.count_love,
      count_wow: count_wow ?? this.count_wow,
      count_sad: count_sad ?? this.count_sad,
      count_angry: count_angry ?? this.count_angry,
      count_like: count_like ?? this.count_like,
      count_haha: count_haha ?? this.count_haha,
      totalCount: totalCount ?? this.totalCount,
      statusType: statusType ?? this.statusType,
      question: question ?? this.question,
      value: value ?? this.value,
    );
  }
}
