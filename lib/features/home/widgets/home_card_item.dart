import 'package:escola/core/components/icons/common_image.dart';
import 'package:escola/core/components/text/my_text.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/home/models/card_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeCardItem extends StatelessWidget {
  final HomeCardModel cardModel;
  const HomeCardItem({
    required this.cardModel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 18.csw),
      padding:
          EdgeInsetsDirectional.only(start: 24.csw, top: 39.csh, end: 7.csw),
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: BorderRadius.circular(15.csh),
      ),
      height: 180.csh,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: CustomSelectableText(
                    cardModel.title ?? "",
                    style: TextStyle(
                      fontSize: 25.sp,
                      fontWeight: FontWeight.w500,
                      color: context.colors.primary,
                    ),
                  ),
                ),
                SizedBox(
                  height: 10.csh,
                ),
                Expanded(
                  flex: 2,
                  child: CustomSelectableText(
                    cardModel.description ?? "",
                    maxLines: 2,
                    style: TextStyle(
                      overflow: TextOverflow.ellipsis,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (validString(cardModel.imageUrl))
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  height: 116.csh,
                  width: 108.csw,
                  child: CommonImage(
                    imageUrl: cardModel.imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            )
        ],
      ),
    );
  }
}
