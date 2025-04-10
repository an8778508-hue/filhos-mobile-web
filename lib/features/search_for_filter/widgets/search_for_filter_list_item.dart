import 'package:escola/core/components/icons/avatar.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/diary/models/school_item.dart';
import 'package:escola/features/search_for_filter/model/search_for_filter_model.dart';
import 'package:escola/shared/assets/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SearchForFilterListItem extends StatelessWidget {
  final SchoolItem item;
  final bool hasBorder, hasArrow;
  const SearchForFilterListItem(
      {super.key,
      required this.item,
      this.hasBorder = true,
      this.hasArrow = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsetsDirectional.only(
          start: 16.w, top: 16.w, bottom: 16.w, end: 8.w),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: !hasBorder
            ? null
            : Border(
                bottom: BorderSide(
                  color: context.colors.scaffold,
                  width: 1.w,
                ),
              ),
      ),
      child: Row(
        children: [
          Avatar(
            avatar: item.avatar,
            defaultAvatar: item.type == SearchForFilterModelType.childOrParent
                ? Assets.icons.classroom.path
                : item.type == SearchForFilterModelType.childOrParent
                    ? Assets.images.childProfileSvg.path
                    : Assets.icons.children.path,
            size: 60.w,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name??'',
                  style: TextStyle(
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w500,
                    color: context.colors.greyDarker,
                  ),
                ),
                if (stringNotNullOrEmpty(item.classRoom))
                  Text(
                    item.classRoom!,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: context.colors.greyDarker,
                    ),
                  ),
              ],
            ),
          ),
          if (hasArrow) ...[
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.arrow_forward_ios,
                color: context.colors.primary,
                size: 22.w,
              ),
            )
          ],
        ],
      ),
    );
  }
}
