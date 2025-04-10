import 'package:escola/features/diary/models/question_category.dart';
import 'package:escola/features/diary/models/questions_models/check_question.dart';
import 'package:escola/features/diary/models/questions_models/duration_question.dart';
import 'package:escola/features/diary/models/questions_models/image_question.dart';
import 'package:escola/features/diary/models/questions_models/info_question.dart';
import 'package:escola/features/diary/models/questions_models/number_question.dart';
import 'package:escola/features/diary/models/questions_models/question.dart';
import 'package:escola/features/diary/models/questions_models/rating_question.dart';
import 'package:escola/features/diary/models/questions_models/select_question.dart';
import 'package:escola/features/diary/presentation/widgets/questions/check_question_widget.dart';
import 'package:escola/features/diary/presentation/widgets/questions/duration_question_widget.dart';
import 'package:escola/features/diary/presentation/widgets/questions/images_question_widget.dart';
import 'package:escola/features/diary/presentation/widgets/questions/info_question_widget.dart';
import 'package:escola/features/diary/presentation/widgets/questions/number_question_widget.dart';
import 'package:escola/features/diary/presentation/widgets/questions/rating_question_widget.dart';
import 'package:escola/features/diary/presentation/widgets/questions/select_question_widget.dart';
import 'package:flutter/material.dart';

class QuestionWidget extends StatelessWidget {
  final Question? question;
  final QuestionCategory? questionCategory;
  const QuestionWidget({super.key, required this.question, required this.questionCategory});

  @override
  Widget build(BuildContext context) {
    if (question == null) return const SizedBox();
    print('QuestionWidget.build 22${question?.type}');


    if (question!.type == QuestionType.checkbox) {
      final currentQuestion = question as CheckQuestion;
      return CheckQuestionWidget(question: currentQuestion, questionCategory: questionCategory,);
    } else if (question!.type == QuestionType.rating) {
      final currentQuestion = question as RatingQuestion;
      return RatingQuestionWidget(question: currentQuestion, questionCategory: questionCategory);
    } else if (question!.type == QuestionType.textarea) {
      final currentQuestion = question as InfoQuestion;
      return InfoQuestionWidget(question: currentQuestion, questionCategory: questionCategory);
    } else if (question!.type == QuestionType.duration) {
      final currentQuestion = question as DurationQuestion;
      return DurationQuestionWidget(question: currentQuestion, questionCategory: questionCategory);
    } else if (question!.type == QuestionType.image) {
      final currentQuestion = question as ImagesQuestion;
      return ImagesQuestionWidget(question: currentQuestion, questionCategory: questionCategory);
    } else if (question!.type == QuestionType.number) {
      final currentQuestion = question as NumberQuestion;
      return NumberQuestionWidget(question: currentQuestion, questionCategory: questionCategory);
    } else if (question!.type == QuestionType.select) {
      final currentQuestion = question as SelectQuestion;
      return SelectQuestionWidget(question: currentQuestion, questionCategory: questionCategory);
    }
    return const SizedBox();
  }
}
