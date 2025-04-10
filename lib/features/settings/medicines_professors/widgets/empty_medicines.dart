import 'package:escola/core/components/empty/empty_widget.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/funuctions/global_functions.dart';
import 'package:escola/features/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EmptyMedicines extends StatelessWidget {
  const EmptyMedicines({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.csw),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 100.h),
            EmptyWidget(
              icon: assetsPath('medicines'),
              size: 70.h,
              title: LocalizationKeys.no_medicines_found.tr(context),
            ),
          ],
        ),
      ),
    );
  }
}
