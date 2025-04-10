import 'package:escola/core/components/image_filter/image_filter.dart';
import 'package:escola/core/components/my_icon.dart';
import 'package:escola/core/components/reactions/bloc/reactions_bloc.dart';
import 'package:escola/core/components/reactions/bloc/reactions_state.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/funuctions/global_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'reactions.dart';

class ReactionPreview extends StatelessWidget {
  const ReactionPreview({
    super.key,
    required this.iconPath,
  });

  final String iconPath;

  @override
  Widget build(BuildContext context) {
    return MyIcon(
      iconPath,
      size: 40.w,
    );
  }
}

class ReactionIcon extends StatelessWidget {
  const ReactionIcon({
    super.key,
    required this.value,
    required this.iconPath,
  });

  final MyReaction value;
  final String iconPath;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReactionsBloc, ReactionsState>(
      builder: (context, state) {
        final count = state.getCount;
        return Container(
          decoration: BoxDecoration(
            color: context.colors.background,
            borderRadius: BorderRadius.circular(200),
          ),
          padding: EdgeInsets.all(3.w),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ImageFilter(
                saturation: state.getMyReaction == value ? 0.0 : -1.0,
                child: MyIcon(
                  iconPath,
                  size: 30.w,
                ),
              ),
              SizedBox(width: 5.w),
              Text(
                count > 0 ? simplifyNumber(context, count) : LocalizationKeys.be_first_to_react.tr(context),
                style: TextStyle(
                  color: context.colors.textColor,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 5.w),
            ],
          ),
        );
      },
    );
  }
}
