// import 'package:escola/core/utils/extensions/responsive_ext.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
//
// class MyIcon extends StatelessWidget {
//   final double? height;
//   final double? width;
//   final String iconPath;
//   final Color? color;
//   final bool networkSvg;
//
//   const MyIcon({
//     Key? key,
//     required this.iconPath,
//     this.color,
//     this.networkSvg = false,
//     this.height,
//     this.width,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return networkSvg
//         ? SvgPicture.network(
//             iconPath,
//             width: width ?? 20.csw,
//             height: height ?? 20.csw,
//             color: color,
//           )
//         : SvgPicture.asset(
//             iconPath,
//             width: width ?? 20.csw,
//             height: height ?? 20.csw,
//             color: color,
//           );
//   }
// }
