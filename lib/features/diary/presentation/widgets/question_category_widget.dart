import 'package:escola/core/components/my_icon.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/diary/models/activities.dart';
import 'package:escola/features/diary/presentation/widgets/menu_button.dart';
import 'package:escola/features/diary/presentation/widgets/questions/question_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/features/diary/models/question_category.dart';

class QuestionCategoryWidget extends StatelessWidget {
  final QuestionCategory category;
  final Activity activity;
  const QuestionCategoryWidget({
    Key? key,
    required this.activity,
    required this.category,
  }) : super(key: key);

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
