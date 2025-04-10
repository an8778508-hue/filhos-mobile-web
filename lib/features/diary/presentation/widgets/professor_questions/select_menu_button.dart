import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/features/diary/models/questions_models/question.dart';
import 'package:escola/features/diary/models/questions_models/select_question.dart';
import 'package:escola/features/diary/models/tamplets/question_template.dart';
import 'package:escola/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:collection/collection.dart';

class SelectMenuButton extends StatelessWidget {
  final QuestionTemplate question;

  const SelectMenuButton({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    final category =
        context.read<DiaryBloc>().categoriesToSend[question.categoryId];

    final questionValue = category?.questions
        ?.firstWhereOrNull((element) => element.id == question.id)
        ?.value;

    if (questionValue != null && question.type == QuestionType.rating) {
      return RatingValue(question: question, rating: questionValue);
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: 100.w),
            child: Text(
              getValue(questionValue),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.black),
            ),
          ),
          SizedBox(width: 10.w),
          Icon(
            Icons.keyboard_arrow_down,
            color: context.colors.primary,
            size: 25.w,
          ),
        ],
      ),
    );
  }

  String getValue(dynamic questionValue) {
    try {
      if (questionValue != null && question.type == QuestionType.checkbox) {
        return questionValue.toString();
      } else if (questionValue != null &&
          question.type == QuestionType.select) {
        final selectItem = questionValue as List<SelectItem>;
        return selectItem[0].value ?? "N/D";
      }
      return "N/D";
    } catch (e) {
      print("error: $e");
      return "N/D";
    }
  }
}

class RatingValue extends StatelessWidget {
  final QuestionTemplate question;
  final int rating;
  const RatingValue({super.key, required this.question, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RatingBar.builder(
          initialRating: rating.toDouble(),
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: true,
          itemSize: 30.w,
          itemCount: 3,
          unratedColor: const Color(0xffdedede),
          itemPadding: EdgeInsets.symmetric(horizontal: 1.w),
          itemBuilder: (context, _) => const Icon(
            Icons.star,
            color: Colors.amber,
          ),
          ignoreGestures: true,
          onRatingUpdate: (rating) {},
        ),
        Icon(
          Icons.keyboard_arrow_down,
          color: context.colors.primary,
          size: 25.w,
        ),
      ],
    );
  }
}
