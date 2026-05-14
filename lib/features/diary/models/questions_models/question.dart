import 'package:equatable/equatable.dart';
import 'package:escola/features/diary/models/main_category.dart';
import 'package:escola/features/diary/models/questions_models/check_question.dart';
import 'package:escola/features/diary/models/questions_models/duration_question.dart';
import 'package:escola/features/diary/models/questions_models/image_question.dart';
import 'package:escola/features/diary/models/questions_models/info_question.dart';
import 'package:escola/features/diary/models/questions_models/number_question.dart';
import 'package:escola/features/diary/models/questions_models/rating_question.dart';
import 'package:escola/features/diary/models/questions_models/select_question.dart';

abstract class Question extends Equatable {
  final int id;
  final QuestionType type;
  final String? title, subtitle;
  final dynamic value;
  // final String? icon_value;

  // final MainCategory? mainCategory;

  const Question({
    required this.value,
    required this.id,
    required this.type,
    this.title,
    // this.icon_value,
    this.subtitle,
    // this.mainCategory,
  });

  // from Json — tolerant: returns null for null/empty input or unknown type so
  // a single backend-added question type can't break the whole diary screen.
  static Question? fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) return null;
    final questionData = json['question_type'] ?? json;
    if (questionData is! Map) return null;
    final MainCategory? mainCategory =
        json['category'] == null ? null : MainCategory.fromJson(json['category']);
    final type = questionData['type'];
    if (type == null) return null;

    switch (type) {
      case 'checkbox':
        return CheckQuestion(
          id: questionData['id'],
          title: questionData['title'],
          subtitle: json['subtitle'],
          value: json['value'],
          icon_value: json['icon_value'].toString(),
          mainCategory: mainCategory,
        );
      case 'rating':
        return RatingQuestion(
          mainCategory: mainCategory,
          id: questionData['id'],
          label: questionData['label'] ?? questionData['title'],
          subtitle: json['subtitle'],
          rating: json['value'],
          icon_value: json['icon_value'].toString(),
        );
      case 'textarea':
        return InfoQuestion(
          mainCategory: mainCategory,
          id: questionData['id'],
          label: questionData['label'] ?? questionData['title'],
          subtitle: json['subtitle'],
          info: json['value'],
          icon_value: json['icon_value'].toString(),
        );
      case 'textfield':
        return InfoQuestion(
          mainCategory: mainCategory,
          id: questionData['id'],
          label: questionData['label'] ?? questionData['title'],
          subtitle: json['subtitle'],
          info: json['value'],
          icon_value: json['icon_value'].toString(),
        );
      case 'duration':
        return DurationQuestion(
          mainCategory: mainCategory,
          id: questionData['id'],
          label: questionData['label'] ?? questionData['title'],
          subtitle: json['subtitle'],
          duration: json['value'].toString(),
          icon_value: json['icon_value'].toString().toString(),
        );
      case 'image':
        return ImagesQuestion(
          mainCategory: mainCategory,
          id: questionData['id'],
          label: questionData['label'] ?? questionData['title'],
          subtitle: json['subtitle'],
          images: json['value'] == null ? null : List<String>.from(json['value']),
        );
      case 'number':
        return NumberQuestion(
          mainCategory: mainCategory,
          id: questionData['id'],
          label: questionData['label'] ?? questionData['title'],
          subtitle: json['subtitle'],
          number: json['value'],
          icon_value: json['icon_value'].toString(),
        );
      case 'select':
        return SelectQuestion(
            mainCategory: mainCategory,
            id: questionData['id'],
            label: questionData['label'] ?? questionData['title'],
            subtitle: json['subtitle'],
            icon_value: json['icon_value'].toString(),
            items: json['value'] == null ?[]:List<SelectItem>.from(json['value'].map((e) => SelectItem.fromJson(e))));
      case 'email':
        return InfoQuestion(
          mainCategory: mainCategory,
          id: questionData['id'],
          label: questionData['label'] ?? questionData['title'],
          subtitle: json['subtitle'],
          info: json['value'],
          icon_value: json['icon_value'].toString(),
        );
      case 'text':
        return InfoQuestion(
          mainCategory: mainCategory,
          id: questionData['id'],
          label: questionData['label'] ?? questionData['title'],
          subtitle: json['subtitle'],
          info: json['value'],
          icon_value: json['icon_value'].toString(),
        );
      default:
        return null;
    }
  }

  // toJson
  Map<String, dynamic> toJson();
}

enum QuestionType { select, checkbox, number, rating, textarea, textfield, duration, image,email }

extension QuestionTypeExtension on QuestionType {
  String get name {
    switch (this) {
      case QuestionType.select:
        return 'select';
      case QuestionType.checkbox:
        return 'checkbox';
      case QuestionType.number:
        return 'number';
      case QuestionType.rating:
        return 'rating';
      case QuestionType.textarea:
        return 'textarea';
      case QuestionType.textfield:
        return 'textarea';
      case QuestionType.duration:
        return 'duration';
      case QuestionType.image:
        return 'image';
      case QuestionType.email:
        return 'email';
      default:
        return 'textarea';
    }
  }
}

extension StringExtension on String {
  QuestionType toQuestionType() {
    switch (this) {
      case 'select':
        return QuestionType.select;
      case 'checkbox':
        return QuestionType.checkbox;
      case 'number':
        return QuestionType.number;
      case 'rating':
        return QuestionType.rating;
      case 'textarea':
        return QuestionType.textarea;
      case 'textfield':
        return QuestionType.textarea;
      case 'duration':
        return QuestionType.duration;
      case 'image':
        return QuestionType.image;
      case 'email':
        return QuestionType.email;
      default:
        return QuestionType.textarea;
    }
  }
}
