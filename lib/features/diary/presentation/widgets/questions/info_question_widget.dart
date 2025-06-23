import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/features/diary/models/question_category.dart';
import 'package:escola/features/diary/models/questions_models/info_question.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class InfoQuestionWidget extends StatelessWidget {
  final InfoQuestion question;
  final QuestionCategory? questionCategory;

  const InfoQuestionWidget({super.key, required this.question, required this.questionCategory});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity ,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(color: context.colors.lightBackground),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Text(
          //   question.title ?? "",
          //   style: TextStyle(
          //       fontSize: 20.sp,
          //       fontWeight: FontWeight.w500,
          //       color: Colors.black),
          // ),
          // Row(
          //   children: [
          //     if(questionCategory?.answer != null)
          //       Text(
          //         questionCategory?.answer?.map((e) => e).join(",") ?? "",
          //         style: TextStyle(
          //             fontSize: 20.sp,
          //             fontWeight: FontWeight.w500,
          //             color: Colors.black),
          //       ),
          //     SizedBox(width: 10.w),
          //   ],
          // ),
          Text(
            question.title ?? "",
            style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black),
          ),
          SizedBox(height: 5.h),
          if(questionCategory?.answer != null)
            Text(
                (questionCategory?.answer?.map((e) => e.toString()).join(", ") ?? "").replaceAll(RegExp(r'[\[\]"]'), ''),
              style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black),
              textAlign: TextAlign.start,
              overflow: TextOverflow.ellipsis,
              maxLines: 30,
            ),

        ],
      ),
    );
  }
  int _getFlexValue(List<dynamic>? answer) {
    if (answer == null) return 1;

    String text = answer.map((e) => e.toString()).join(", ").replaceAll(RegExp(r'[\[\]"]'), '');

    // Check if text is likely to span multiple lines
    // This assumes text longer than 40 characters will wrap
    return (text.length > 40 || text.contains('\n')) ? 3 : 1;
  }
}
