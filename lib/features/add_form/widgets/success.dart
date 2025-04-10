// import 'package:escola/core/localization/localization_keys.dart';
// import 'package:escola/core/utils/extensions/colors_ext.dart';
// import 'package:escola/core/utils/extensions/responsive_ext.dart';
// import 'package:escola/shared/assets/assets.gen.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
//
// class SuccessDialog extends StatefulWidget {
//   const SuccessDialog({
//     super.key,
//   });
//
//   @override
//   State<SuccessDialog> createState() => _SuccessDialogState();
// }
//
// class _SuccessDialogState extends State<SuccessDialog> {
//   @override
//   void initState() {
//     super.initState();
//     Future.delayed(
//       const Duration(seconds: 3),
//       () {
//         if (mounted) {
//           Navigator.of(context).pop();
//         }
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         SizedBox(height: MediaQuery.of(context).size.height * .125),
//         Dialog(
//           insetPadding: EdgeInsets.symmetric(horizontal: 24.csw),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10.r),
//           ),
//           child: Padding(
//             padding: EdgeInsets.symmetric(
//               horizontal: 20.csw,
//               vertical: 50.csh,
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Assets.icons.successGlow.svg(
//                   width: 115.sp,
//                   height: 115.sp,
//                 ),
//                 SizedBox(height: 34.csh),
//                 Text(
//                   LocalizationKeys.success_save_prescription.tr(context),
//                   style: TextStyle(
//                     color: context.colors.textColor,
//                     fontSize: 20.sp,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
