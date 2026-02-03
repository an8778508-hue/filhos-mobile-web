import 'package:escola/features/diary/models/activities.dart';
import 'package:escola/features/diary/presentation/widgets/questions/question_widget.dart';
import 'package:flutter/material.dart';

import 'package:escola/features/diary/models/question_category.dart';

class QuestionCategoryWidget extends StatelessWidget {
  final QuestionCategory category;
  final Activity activity;
  const QuestionCategoryWidget({
    super.key,
    required this.activity,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    // if (category.questions?.isEmpty == true) return const SizedBox();
    final firstChild = activity.childModel;

    return Column(
      children: [

        QuestionWidget(question: category.question,questionCategory: category,),
        // ListView.builder(
        //   shrinkWrap: true,
        //   itemCount: category.questions?.length ?? 0,
        //   padding: EdgeInsets.zero,
        //   physics: const NeverScrollableScrollPhysics(),
        //   itemBuilder: (context, index) {
        //     final question = category.questions?[index];
        //     return ;
        //   },
        // ),
      ],
    );
  }
}
