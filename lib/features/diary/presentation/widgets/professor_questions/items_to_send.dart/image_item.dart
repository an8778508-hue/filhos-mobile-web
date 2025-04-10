import 'package:escola/core/components/image/image_uploader.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/features/diary/models/questions_models/image_question.dart';
import 'package:escola/features/diary/models/tamplets/question_template.dart';
import 'package:escola/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ImagesItem extends StatelessWidget {
  final QuestionTemplate question;

  const ImagesItem({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    return ImagesField(
      onChange: (images) => handleQuestionChanges(context, images),
      backgroundColor: context.colors.lightBackground,
      title: question.title ?? LocalizationKeys.attachments.tr(context),
      titleStyle: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w500, color: Colors.black),
    );
  }

  void handleQuestionChanges(BuildContext context, List<String> images) {
    if (images.isEmpty) {
      context.read<DiaryBloc>().add(RemoveQuestion(questionId: question.id, categoryId: question.categoryId));
    } else {
      final imageQuestion = ImagesQuestion(
        id: question.id,
        label: question.title,
        images: images,
      );
      context.read<DiaryBloc>().add(AddQuetsion(question: imageQuestion, categoryId: question.categoryId));
    }
  }
}
