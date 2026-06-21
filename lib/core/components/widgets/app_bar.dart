import 'package:escola/core/components/icons/common_image.dart';
import 'package:escola/core/components/image/photo_viewer.dart';
import 'package:escola/core/config/config.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/main/bloc/main_bloc.dart';
import 'package:escola/features/notifications/notifications_page.dart';
import 'package:escola/shared/assets/assets.gen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MyAppBar({
    super.key,
    this.title,
    this.image,
    this.hasNotification = true,
    this.addButton = false,
    this.filterButton = false,
    this.actionWidget,
    this.color,
    this.addFunction,
    this.filterFunction,
    this.hasAvatar = false,
    this.isHome = false,
  });

  final String? title;
  final String? image;
  final bool hasAvatar;
  final bool hasNotification;
  final Widget? actionWidget;
  final Color? color;
  final bool addButton;
  final bool isHome;

  final bool filterButton;
  final Function()? addFunction;
  final Function()? filterFunction;

  /// Toolbar height. On web the toolbar content (avatar / two-line greeting /
  /// notification button) renders a few logical pixels taller than the fixed
  /// 80px design height, producing the "overflowed by 19 pixels" banner. Give
  /// it extra headroom on web so the content never overflows.
  double get _toolbarHeight => 80.h + (kIsWeb ? 20.0 : 0.0);

  @override
  Widget build(BuildContext context) {
    final currentId = BlocProvider.of<MainBloc>(context, listen: true).currentId;
    final canPop = ModalRoute.of(context)!.canPop;
    final isHome = (currentId == PageID.home.name) && this.isHome;
    final isMainPage = currentId == PageID.home.name ||
        currentId == PageID.diary.name ||
        currentId == PageID.settings.name ||
        currentId == PageID.events.name;
    final hasBackButton = canPop || !isMainPage ;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    return Container(
        color: color ?? context.colors.primary,
        child: Column(children: [
          AppBar(
            backgroundColor: color ?? context.colors.primary,
            toolbarHeight: _toolbarHeight,
            titleSpacing: 0,
            automaticallyImplyLeading: false,
            leading: hasBackButton
                ? GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (canPop) {
                        Navigator.of(context).pop();
                      } else if (!isHome) {
                        context.read<MainBloc>().add(ChangePage(id: PageID.home.name));
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.all(10.w),
                      child: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: context.colors.secondaryTextColor,
                      ),
                    ),
                  )
                : null,
            title: Row(
              children: [
                if (hasAvatar) ...[
                  if (validString(title))
                    Padding(
                      padding: EdgeInsetsDirectional.only(end: 10.csw, start: hasBackButton ? 0 : 20.csw),
                      child: SizedBox(
                        width: 51.csh,
                        height: 51.csh,
                        child: validString(image)
                            ? GestureDetector(
                                onTap: () {
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (context) => PhotoViewer(url: image!, tag: image!)));
                                },
                                child: ClipOval(
                                    child: CommonImage(
                                  imageUrl: image!,
                                  fit: BoxFit.cover,
                                  fallBackImagePath: Assets.icons.person.path,
                                )),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  color: context.colors.background,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Assets.icons.person.svg(
                                      color: color ?? context.colors.primary,
                                      width: 24.sp,
                                      height: 24.sp,
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                ],
                if (validString(title))
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: (!hasBackButton && !hasAvatar) ? 10.csw : 0),
                      child: Text(
                        title!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.colors.secondaryTextColor,
                          fontSize: 19.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              if (addButton)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: addFunction,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 20.h),
                    child: SvgPicture.asset(
                      'assets/icons/adding.svg',
                      height: 16.5.h,
                      width: 16.5.w,
                    ),
                  ),
                ),
              if (filterButton)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: filterFunction,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 20.h),
                    child: SvgPicture.asset(
                      'assets/icons/filter.svg',
                      height: 17.5.h,
                      width: 20.w,
                    ),
                  ),
                ),
              if (actionWidget != null) actionWidget!,
              if (hasNotification)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()));
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.w, horizontal: 20.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipOval(
                          child: Container(
                            width: isTablet? 20.w: 35.w,
                            height: isTablet? 20.w: 35.w,
                            color: context.colors.background,
                            child: Icon(
                              Icons.notifications,
                              size: 20.w,
                              color: context.colors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ]));
  }

  @override
  Size get preferredSize => Size.fromHeight(_toolbarHeight);
}
