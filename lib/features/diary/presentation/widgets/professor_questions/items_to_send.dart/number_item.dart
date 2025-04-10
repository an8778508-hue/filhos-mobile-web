import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/features/diary/models/questions_models/number_question.dart';
import 'package:escola/features/diary/models/tamplets/question_template.dart';
import 'package:escola/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NumberItem extends StatefulWidget {
  final QuestionTemplate question;
  const NumberItem({super.key, required this.question});

  @override
  State<NumberItem> createState() => _NumberItemState();
}

class _NumberItemState extends State<NumberItem> {
  int number = 0;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() => number++);
              sendQuestion(context, number);
            },
            child: Icon(
              Icons.add,
              color: context.colors.primary,
              size: 27.w,
            ),
          ),
          SizedBox(width: 12.w),
          Container(
            constraints: BoxConstraints(maxWidth: 100.w),
            child: Text(
              number.toString(),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w400, color: Colors.black),
            ),
          ),
          SizedBox(width: 12.w),
          GestureDetector(
            onTap: () {
              if (number > 0) {
                setState(() => number--);
                sendQuestion(context, number);
              }
            },
            child: Icon(
              Icons.remove,
              color: context.colors.primary,
              size: 27.w,
            ),
          ),
        ],
      ),
    );
  }

  void sendQuestion(BuildContext context, int number) {
    final numberQuestion = NumberQuestion(id: widget.question.id, label: widget.question.title, number: number);

    if (number == 0) {
      context
          .read<DiaryBloc>()
          .add(RemoveQuestion(questionId: numberQuestion.id, categoryId: widget.question.categoryId));
    } else {
      context.read<DiaryBloc>().add(AddQuetsion(question: numberQuestion, categoryId: widget.question.categoryId));
    }
  }
}
