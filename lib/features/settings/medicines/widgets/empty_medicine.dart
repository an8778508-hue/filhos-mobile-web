import 'package:escola/core/components/buttons/custom_button.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/features/add_form/add_form_screen.dart';
import 'package:escola/features/settings/medicines/bloc/medicines_bloc.dart';
import 'package:escola/features/settings/medicines/bloc/medicines_events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EmptyMedicine extends StatelessWidget {
  const EmptyMedicine({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.center, children: [
      SizedBox(
        height: 80.csh,
      ),
      SvgPicture.asset(
        'assets/icons/diagnosis.svg',
        height: 114.csh,
        width: 114.csw,
      ),
      SizedBox(
        height: 40.csh,
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 15.w),
              child: Text(
                LocalizationKeys.there_are_no_medicines_added_now.tr(context),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25.sp,
                  fontWeight: FontWeight.w600,
                  color: context.colors.primaryLight,
                ),
              ),
            ),
            SizedBox(
              height: 18.csh,
            ),
            Text(
              LocalizationKeys.you_can_add_the_medicine.tr(context),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
                color: context.colors.primaryLight,
              ),
            ),
            SizedBox(
              height: 40.csh,
            ),
            CustomButton(
              title: LocalizationKeys.add_medicine.tr(context),
              onTap: () async {
                final bloc = BlocProvider.of<MedicinesBloc>(context);
                final b = await Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) => const AddFormScreen(type: AddFormType.medicine)));
                if (b == true) {
                  bloc.add(const FetchMedicines());
                }
              },
            )
          ],
        ),
      ),
    ]);
  }
}
