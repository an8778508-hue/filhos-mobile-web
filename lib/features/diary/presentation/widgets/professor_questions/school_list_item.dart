import 'package:escola/core/components/icons/avatar.dart';
import 'package:escola/core/components/icons/common_image.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/models/user_model.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/widgets_ext.dart';
import 'package:escola/core/utils/funuctions/widget_functions.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/chat/models/chat_user.dart';
import 'package:escola/features/chat/presentation/chat_screen.dart';
import 'package:escola/features/diary/models/school_item.dart';
import 'package:escola/shared/assets/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SchoolListItem extends StatelessWidget {
  final SchoolItem item;
  final bool hasBorder, hasArrow, showChatIcon;
  final bool? selected;
  final Color? textColor;
  final double? titleSize, subTitleSize;
  final double? verticalPadding;
  const SchoolListItem(
      {super.key,
      required this.item,
      this.hasBorder = true,
      this.hasArrow = true,
      this.showChatIcon = false,
      this.selected,
      this.verticalPadding,
      this.textColor,
      this.titleSize,
      this.subTitleSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsetsDirectional.only(
          start: 16.w, top: verticalPadding ?? 16.w, bottom: verticalPadding ?? 16.w, end: 8.w),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: !hasBorder
            ? null
            : Border(
                bottom: BorderSide(
                  color: context.colors.scaffold,
                  width: 2.w,
                ),
              ),
      ),
      child: Row(
        children: [
          Avatar(
            avatar: item.avatar,
            defaultAvatar: item.type == SchoolItemType.classType
                ? Assets.icons.classroom.path
                : item.type == SchoolItemType.childType
                    ? Assets.images.childProfileSvg.path
                    : Assets.icons.children.path,
            size: 50.w,
          ),
          SizedBox(width: 20.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.name ?? '',
                        style: TextStyle(
                          fontSize: titleSize ?? 19.sp,
                          fontWeight: FontWeight.w500,
                          color: textColor ?? context.colors.greyDarker,
                        ),
                      ),
                    ),
                    if (item.parent != null && showChatIcon) ...[
                      CommonImage(
                        imageUrl: Assets.icons.chatIcon.path,
                        size: 30.w,
                        color: context.colors.primary,
                      ).splash(onPressed: () => openChatScreen(context))
                    ]
                  ],
                ),
                if (stringNotNullOrEmpty(item.classRoom)) ...[
                  SizedBox(height: 5.h),
                  Text(
                    item.classRoom!,
                    style: TextStyle(
                      fontSize: subTitleSize ?? 14.sp,
                      fontWeight: FontWeight.w300,
                      color: textColor ?? context.colors.greyDarker,
                    ),
                  ),
                ],
                if (item.type != SchoolItemType.allChildType &&
                    item.type != SchoolItemType.all &&
                    item.type != SchoolItemType.allTeachersType &&
                    item.type != SchoolItemType.childType) ...[
                  SizedBox(height: 5.h),
                  Text(
                    item.type.name.tr(context),
                    style: TextStyle(
                      fontSize: subTitleSize ?? 14.sp,
                      fontWeight: FontWeight.w300,
                      color: textColor ?? context.colors.greyDarker,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (selected != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.0.w),
              child: Icon(
                selected == true ? Icons.circle : Icons.circle_outlined,
                color: selected == true ? context.colors.primary : context.colors.greyDarker,
                size: 18.w,
              ),
            ),
          if (hasArrow) ...[
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.arrow_forward_ios,
                color: context.colors.primary,
                size: 18.w,
              ),
            )
          ],
        ],
      ),
    );
  }

  void openChatScreen(BuildContext context) {
    final parent = item.parent;
    if (parent != null) {
      ChatUser contact =
          ChatUser(id: parent.id.toString(), name: parent.name, avatar: parent.image, type: UserType.parent);
      final child = item.type == SchoolItemType.childType ? item.getChildModel() : null;
      WidgetFunctions.navigateTo(
          context,
          ChatScreen(
            contact: contact,
            child: child,
          ));
    }
  }
}
