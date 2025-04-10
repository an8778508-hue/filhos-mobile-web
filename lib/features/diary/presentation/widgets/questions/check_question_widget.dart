import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/features/diary/models/question_category.dart';
import 'package:escola/features/diary/models/questions_models/check_question.dart';
import 'package:escola/features/diary/presentation/widgets/professor_questions/items_to_send.dart/dropdown_question_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CheckQuestionWidget extends StatelessWidget {
  final CheckQuestion question;
  final QuestionCategory? questionCategory;

  const CheckQuestionWidget({super.key, required this.question, required this.questionCategory});

  @override
  Widget build(BuildContext context) {
    print('CheckQuestionWidget.build ${questionCategory?.icon_value}');
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 20.h),
      decoration: BoxDecoration(color: context.colors.lightBackground),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            question.title ?? "",
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w500, color: Colors.black),
          ),
          Row(
            children: [
              if (questionCategory?.answer != null)
                Text(
                  (questionCategory!.answer!.map((e) => e).join(",")),
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              // SizedBox(width: 10.w),
              // Icon(Icons.check_circle,
              //     color: context.colors.successLight, size: 30.sp),
              getDynamicQuestionValue(icon_value: questionCategory?.icon_value, context: context, isAnswer: true),
            ],
          ),
        ],
      ),
    );
  }
}
