import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/features/diary/models/questions_models/question.dart';
import 'package:escola/features/diary/models/tamplets/question_template.dart';
import 'package:escola/features/diary/presentation/widgets/professor_questions/items_to_send.dart/image_item.dart';
import 'package:escola/features/diary/presentation/widgets/professor_questions/items_to_send.dart/info_item.dart';
import 'package:escola/features/diary/presentation/widgets/professor_questions/items_to_send.dart/item_to_send.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class QuestionTemplateItem extends StatelessWidget {
  final QuestionTemplate question;
  const QuestionTemplateItem({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    if (question.type == QuestionType.image) {
      return ImagesItem(question: question);
    } else if (question.type == QuestionType.textarea) {
      return InfoItem(question: question);
    }else if(question.type == QuestionType.email){
      return EmailItem(question: question);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 25.h),
      decoration: BoxDecoration(
        color: context.colors.lightBackground,
        border: Border(
          bottom: BorderSide(color: Colors.white, width: 1.w),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Text(
              question.title ?? "",
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w500, color: Colors.black),
            ),
          ),
          ItemToSend(question: question)
        ],
      ),
    );
  }
}
