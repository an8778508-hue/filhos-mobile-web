import 'package:collection/collection.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/funuctions/date_functions.dart';
import 'package:escola/features/diary/models/questions_models/duration_question.dart';
import 'package:escola/features/diary/models/tamplets/question_template.dart';
import 'package:escola/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DurtionItem extends StatelessWidget {
  final QuestionTemplate question;

  const DurtionItem({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    final category = context.read<DiaryBloc>().categoriesToSend[question.categoryId];

    final questionValue = category?.questions?.firstWhereOrNull((element) => element.id == question.id)?.value;

    return GestureDetector(
      onTap: () async {
        showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(DateTime.now()),
        ).then((time) {
          if (time != null) {
            final durationQuestion = DurationQuestion(
              id: question.id,
              label: question.title,
              duration: DateFunctions.formatTimeOfDay(time),
            );
            context.read<DiaryBloc>().add(AddQuetsion(question: durationQuestion, categoryId: question.categoryId));
          }
        });
      },
      child: Text(
        questionValue ?? "_ _  :  _ _",
        style: TextStyle(fontSize: 23.sp, fontWeight: FontWeight.w400, color: context.colors.primary),
      ),
    );
  }
}
