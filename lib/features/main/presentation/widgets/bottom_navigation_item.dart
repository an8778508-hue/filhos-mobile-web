import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BottomNavigationItemWidget extends StatelessWidget {
  final BottomNavigationItem item;
  final Function(String) onTap;
  final String selectedId;
  final int? notificationNumber;

  const BottomNavigationItemWidget(
      {super.key, required this.item, required this.onTap, required this.selectedId, this.notificationNumber});

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedId == item.id;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(item.id),
        child: Container(
          color: Colors.transparent,
          child: Stack(
            alignment: AlignmentDirectional.center,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 0.csh),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: 50.w,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          color: isSelected ? context.colors.secondary : Colors.transparent,
                          height: 3.csh,
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Flexible(
                      child: Column(
                        children: [
                          Flexible(child: item.icon),
                          SizedBox(height: 5.h),
                          Text(
                            item.title,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                              color: !isSelected ? context.colors.greyDark : context.colors.secondary,
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (notificationNumber != null && notificationNumber != 0)
                Align(
                  alignment: AlignmentDirectional.topCenter,
                  child: Container(
                    margin: EdgeInsetsDirectional.only(start: 20.w),
                    padding: EdgeInsets.all(10.h),
                    decoration: BoxDecoration(
                      color: context.colors.alert,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      notificationNumber.toString(),
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: context.colors.secondaryTextColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// if (isSelected)
//   Align(
//     alignment: Alignment.topCenter,
//     child: Container(
//       color: context.colors.secondary,
//       height: 2,
//     ),
//   ),

class BottomNavigationItem {
  final String title;
  final Widget icon;
  final String id;

  BottomNavigationItem({
    required this.title,
    required this.icon,
    required this.id,
  });
}
