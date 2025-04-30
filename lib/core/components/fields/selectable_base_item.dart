import 'package:escola/core/components/my_icon.dart';
import 'package:escola/core/utils/funuctions/global_functions.dart';
import 'package:escola/core/utils/size_config.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SelectableBaseItem<T> extends StatelessWidget {
  const SelectableBaseItem({Key? key, required this.isSelected, required this.title, required this.model})
      : super(key: key);
  final bool isSelected;

  final String title;

  final T model;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: getWidthByNumber(10)),
      child: InkWell(
        onTap: () => Navigator.pop(context, model),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 15.h,horizontal: 15.w),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xffF4F5F6) : Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(10.r)),
            border: Border.all(color: Color(0xffECECEC), width: 1.w),
          ),
          child: Row(
            children: [
              if (validString(title))
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Color(0xff4a4a4a),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (isSelected) MyIcon( assetsPath('selected'))
            ],
          ),
        ),
      ),
    );
  }
}
