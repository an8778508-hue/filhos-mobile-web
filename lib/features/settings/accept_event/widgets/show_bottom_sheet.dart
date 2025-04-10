import 'dart:io';

import 'package:escola/core/components/buttons/custom_button.dart';
import 'package:escola/core/components/text/text_html.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

Future<dynamic> showButtonSheet({
  required BuildContext context,
  required Function()? sendReceipt,
  required Function()? uploadImage,
  required ValueNotifier<File?> imageController,
  required String paymentInfo,
}) {
  return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * .75,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 35.csh, horizontal: 20.csw),
              width: double.maxFinite,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    LocalizationKeys.payment_information.tr(context),
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.csh),
                  Text(
                    LocalizationKeys.for_add_the_following.tr(context),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 27.csh),
                  TextHtml(
                    paymentInfo,
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: context.colors.primary,
                      fontSize: 25.sp,
                    ),
                  ),
                  // RichText(
                  //   text: TextSpan(
                  //     children: <TextSpan>[
                  //       TextSpan(
                  //         text: paymentInfo,
                  //         style: TextStyle(fontWeight: FontWeight.w400, color: context.colors.primary, fontSize: 25.sp),
                  //       ),
                  //       // TextSpan(
                  //       //   text: pix,
                  //       //   style: TextStyle(fontWeight: FontWeight.w600, color: context.colors.primary, fontSize: 25.sp),
                  //       // ),
                  //     ],
                  //   ),
                  // ),
                  SizedBox(height: 27.csh),
                  Divider(
                    color: context.colors.greyLight.withOpacity(0.3),
                    endIndent: 20.csw,
                    indent: 20.csw,
                  ),
                  ValueListenableBuilder(
                    valueListenable: imageController,
                    builder: (context, value, child) => Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: uploadImage,
                          child: value != null
                              ? Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20.csh),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10.r),
                                    clipBehavior: Clip.antiAlias,
                                    child: SizedBox(
                                      width: double.maxFinite,
                                      height: 200.h,
                                      child: Image.file(
                                        value,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: double.maxFinite,
                                  padding: EdgeInsets.symmetric(vertical: 30.csh),
                                  child: SvgPicture.asset(
                                    'assets/icons/upload_image.svg',
                                    height: 75.csh,
                                    width: 77.csw,
                                  ),
                                ),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (value == null) {
                              uploadImage!();
                            } else {
                              imageController.value = null;
                            }
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 10.0.h, horizontal: 20.w),
                            child: Text(
                              (value != null ? LocalizationKeys.cancel : LocalizationKeys.attach_the_proof_of_payment).tr(context),
                              style: TextStyle(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w500,
                                color: context.colors.primaryLight,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 17.csh),
                  CustomButton(
                    title: LocalizationKeys.send_the_receipt.tr(context),
                    onTap: sendReceipt,
                  ),
                ],
              ),
            ),
          ),
        );
      });
}
