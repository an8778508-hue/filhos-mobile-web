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
  /// Extract text part before colon
  String _extractText(String? value) {
    if (value == null || !value.contains(":")) {
      return value ?? "";
    }
    return value.split(":")[0].trim();
  }

  /// Extract star count from number after colon
  int? _extractStarCount(String? value) {
    if (value == null || !value.contains(":")) {
      return null;
    }

    try {
      final numberPart = value.split(":")[1].trim();
      return int.parse(numberPart);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    print('CheckQuestionWidget.build22 ${item?.icon_value}');
    final iconIsSizedBox =
        CommonImage(imageUrl: item?.icon, size: 20.w).runtimeType == SizedBox;
    final text = _extractText(item?.value);
    final starCount = _extractStarCount(item?.value);
    debugPrint('iconIsSizedBox: $iconIsSizedBox');
    debugPrint('text: $text');
    debugPrint('starCount: $starCount');
    return Row(
      children: [
        if (item?.icon != null) ...[
          CommonImage(imageUrl: item!.icon, size: 20.w),
          if (!iconIsSizedBox) SizedBox(width: 10.w)
        ]else getDynamicQuestionValue( icon_value:  item?.icon_value, context: context, isAnswer: false),
        Flexible(
          child: Text(
            text ,
            textAlign: TextAlign.start ,
            // (item?.value ?? ""),
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
        ),
          if (starCount != null && starCount >= 0)
          SizedBox(width: 10.w),
            if (starCount != null && starCount >= 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: starCount >0?
            List.generate(
              starCount,
                  (index) =>  Icon(
                Icons.star,
                color: Colors.amber,
                size: 18.sp,
              ),
            ):
            List.generate(
              1,
                  (index) =>  Icon(
                Icons.star,
                color: Colors.grey,
                size: 18.sp,
              ),
            )
            ,
          ),
      ],
    );
  }
}
