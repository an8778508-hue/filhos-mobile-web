import 'package:escola/features/diary/models/questions_models/question.dart';
import 'package:escola/features/diary/models/tamplets/question_template.dart';
import 'package:escola/features/diary/presentation/widgets/professor_questions/items_to_send.dart/dropdown_question_menu.dart';
import 'package:escola/features/diary/presentation/widgets/professor_questions/items_to_send.dart/duration_item.dart';
import 'package:escola/features/diary/presentation/widgets/professor_questions/items_to_send.dart/number_item.dart';
import 'package:flutter/material.dart';

class ItemToSend extends StatelessWidget {
  final QuestionTemplate question;
  const ItemToSend({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    if (question.type == QuestionType.duration) {
      return DurtionItem(question: question);
    } else if (question.type == QuestionType.number) {
      return NumberItem(question: question);
    } else {
      return DropDownQuestionMenu(question: question);
    }
  }
}
