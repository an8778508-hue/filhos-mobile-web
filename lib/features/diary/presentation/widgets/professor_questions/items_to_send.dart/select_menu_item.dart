import 'package:escola/core/components/icons/common_image.dart';
import 'package:escola/features/diary/models/questions_models/select_question.dart';
import 'package:escola/features/diary/models/tamplets/question_template.dart';
import 'package:escola/features/diary/presentation/widgets/professor_questions/items_to_send.dart/dropdown_question_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SelectMenuItem extends StatelessWidget {
  final SelectItem? item;
  final QuestionTemplate question;
  const SelectMenuItem({super.key, this.item, required this.question});

  @override
  Widget build(BuildContext context) {
    print('CheckQuestionWidget.build ${item?.icon_value}');
    final iconIsSizedBox =
        CommonImage(imageUrl: item?.icon, size: 20.w).runtimeType == SizedBox;

    return Row(
      children: [
        if (item?.icon != null) ...[
          CommonImage(imageUrl: item!.icon, size: 20.w),
          if (!iconIsSizedBox) SizedBox(width: 10.w)
        ]else getDynamicQuestionValue( icon_value:  item?.icon_value, context: context, isAnswer: false),
        Flexible(
          child: Text(
            (item?.value ?? ""),
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
