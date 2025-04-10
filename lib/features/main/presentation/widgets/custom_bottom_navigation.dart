import 'package:escola/core/components/my_icon.dart';
import 'package:escola/core/config/config.dart';
import 'package:escola/core/config/widgets/config_builder.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:escola/features/main/presentation/widgets/bottom_navigation_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomBottomNavigation extends StatelessWidget {
  final String selectedId;
  final Function(String) onTap;

  const CustomBottomNavigation({super.key, required this.selectedId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85.h,
      width: double.infinity,
      color: context.colors.background,
      padding: EdgeInsets.symmetric(horizontal: 20.csw),
      child: ConfigSelector<List<BottomBarItemModel>>(
        selector: (config) => config.bottomBar,
        builder: (context, items) => Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ...items.map(
              (e) => BottomNavigationItemWidget(
                onTap: onTap,
                selectedId: selectedId,
                notificationNumber: e.id == PageID.settings.name ? unReadMessages(context) : null,
                item: BottomNavigationItem(
                  id: e.id,
                  title: validString(e.translationKey) ?e.translationKey.tr(context):e.title,
                  icon: MyIcon(
                    selectedId == e.id ? e.activeIcon : e.inActiveIcon,
                    size: 26.w,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int unReadMessages(BuildContext context) {
    return context.watch<ChatBloc>().unReadMessagesCount;
  }
}
