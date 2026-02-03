import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CheckMenuItem extends StatelessWidget {
  final  bool checked;
  const CheckMenuItem({super.key, required this.checked});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 25.w,
          height: 25.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: checked ? context.colors.successLight : Colors.red,
          ),
          child: Center(
            child: Icon(
              checked ? Icons.check : Icons.close,
              color: Colors.white,
              size: 18.w,
            ),
          ),
        ),
        // SizedBox(width: 10.w),
        // Flexible(
        //   child: Text(
        //     getText(index, question, context),
        //     style: TextStyle(
        //       fontSize: 20.sp,
        //       fontWeight: FontWeight.w400,
        //       color: Colors.black,
        //     ),
        //   ),
        // ),
      ],
    );
  }

  // static getText(int index, QuestionTemplate question, context) {
  //   final onValue = stringNotNullOrEmpty(question.checkOnValue)
  //       ? question.checkOnValue
  //       : LocalizationKeys.yes.tr(context);
  //
  //   final offValue = stringNotNullOrEmpty(question.checkOffValue)
  //       ? question.checkOffValue
  //       : LocalizationKeys.no.tr(context);
  //   return (index == 0 ? onValue : offValue);
  // }
}
