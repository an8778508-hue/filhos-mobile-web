import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/widgets_ext.dart';
import 'package:escola/features/diary/models/question_category.dart';
import 'package:escola/features/diary/models/questions_models/select_question.dart';
import 'package:escola/features/diary/presentation/widgets/professor_questions/items_to_send.dart/dropdown_question_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SelectQuestionWidget extends StatelessWidget {
  final SelectQuestion question;
  final QuestionCategory? questionCategory;

  const SelectQuestionWidget({super.key, required this.question, required this.questionCategory});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.h, ),
      decoration: BoxDecoration(
        color: context.colors.lightBackground,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          Text(
            (question.title ?? ""),
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w500, color: Colors.black),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  questionCategory?.answer?.map((e) => e).join(",") ?? "",
                  // item.value ?? "",
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w400, color: Colors.black),
                ),
              ),
              getDynamicQuestionValue(icon_value: questionCategory?.icon_value, context: context, isAnswer: false),
            ],
          ).addPadding(padding: EdgeInsets.symmetric(horizontal: 5.w)),
          SizedBox(height: 16.h),
          Container(
            color: context.colors.scaffold,
            height: 1.h,
          ),
        ],
      ),
    );
  }
}
