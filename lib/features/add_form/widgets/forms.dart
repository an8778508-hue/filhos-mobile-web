import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/add_form/widgets/collection.dart';
import 'package:escola/features/add_form/widgets/group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:separated_column/separated_column.dart';

class FormSection extends StatelessWidget {
  const FormSection({
    Key? key,
    required this.children,
    this.title,
  }) : super(key: key);

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isInGroup = context.findAncestorWidgetOfExactType<GroupWidget>() != null;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isInGroup ? 0 : 14.csw),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (validString(title))
            Padding(
              padding: EdgeInsets.only(bottom: 10.csh),
              child: Text(
                title!.tr(context),
                style: TextStyle(
                  color: context.colors.textColor,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (validList(children))
            SeparatedColumn(
              separatorBuilder: (context, index) => SizedBox(height: 14.csh),
              mainAxisSize: MainAxisSize.min,
              children: [
                ...children,
              ],
            ),
        ],
      ),
    );
  }
}

class FormCard extends StatelessWidget {
  const FormCard({
    Key? key,
    required this.child,
    this.radius,
    this.forceNested = false,
    this.forceNotNested = false,
  }) : super(key: key);

  final Widget child;
  final bool forceNested;
  final bool forceNotNested;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final isChildOfCollection = context.findAncestorWidgetOfExactType<CollectionWidget>() != null;
    bool isNested = isChildOfCollection;
    if(forceNested){
      isNested = true;
    }
    if(forceNotNested){
      isNested = false;
    }
    return Material(
      color: isNested ? Colors.transparent : context.colors.background,
      borderRadius: isNested ? null : BorderRadius.circular(radius??5.r),
      shape: isNested
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.r),
              side: BorderSide(
                color: context.colors.disabled,
                width: 1,
              ),
            )
          : null,
      child: child,
    );
  }
}
