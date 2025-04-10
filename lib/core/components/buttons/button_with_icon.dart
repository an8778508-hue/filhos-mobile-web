import 'package:escola/core/components/icons/common_image.dart';

import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Custom button that can be used allover the project

class ButtonWithIcon extends StatelessWidget {
  const ButtonWithIcon({
    super.key,
    required this.onPressed,
    required this.text,
    //todo
    this.buttonBackgroundColor = const Color(0xffffffff),
    this.buttonOverlayColor = const Color(0x22f5f5f5),
    this.textColor = const Color(0x22f5f5f5),
    this.borderColor,
    this.borderWidth,
    this.firstIconColor,
    this.firstIconPathRadius = 0.0,
    this.lastIconColor,
    this.firstIconPath,
    this.firstIconAsset,
    this.lastIconPath,
    this.elevation,
    this.fontSize,
    this.padding,
    this.isTextExpanded = false,
    this.firstIconBoxFit = BoxFit.contain,
    this.isLoading = false,
    this.hasBorder = false,
    this.hasError = false,
    this.firstIconHeight,
    this.firstIconWidget,
    this.lastIconHeight,
    this.firstIconWidth,
    this.lastIconWidth,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.firstIconSpaceWidth,
    this.firstIconHeightPercentage = 0.035,
    this.lastIconHeightPercentage = 0.040,
    this.firstIconWidthPercentage = 0.01,
    this.lastIconWidthPercentage = 0.040,
    this.marginHeight = 20,
    this.marginWidth = 33,
    this.borderRadius,
    this.fontWeight,
  });

  final Function onPressed;
  final String? text;
  final Color buttonBackgroundColor;
  final Color buttonOverlayColor;
  final Color textColor;
  final double? elevation;
  final double? fontSize;
  final double? borderRadius;
  final double? borderWidth;
  final Color? borderColor;
  final String? firstIconAsset;
  final Widget? firstIconWidget;
  final String? firstIconPath;
  final String? lastIconPath;
  final MainAxisAlignment mainAxisAlignment;
  final TextAlign textAlign;
  final BoxFit firstIconBoxFit;

  final FontWeight? fontWeight;
  final TextDirection? textDirection;

  final EdgeInsetsGeometry? padding;
  final Color? firstIconColor;
  final Color? lastIconColor;
  final double? firstIconWidth;
  final double firstIconPathRadius;
  final double? firstIconHeight;
  final double firstIconHeightPercentage;
  final double firstIconWidthPercentage;
  final double? firstIconSpaceWidth;

  final double? lastIconWidth;
  final double? lastIconHeight;
  final double lastIconHeightPercentage;
  final double lastIconWidthPercentage;

  final double marginHeight;
  final double marginWidth;

  final bool isTextExpanded;
  final bool isLoading;
  final bool hasBorder, hasError;

  @override
  Widget build(BuildContext context) {
    return !isLoading
        ? Container(
            padding: const EdgeInsets.all(0.0),
            margin: EdgeInsets.symmetric(
              horizontal: marginWidth.csw,
              vertical: marginHeight.csh,
            ),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              border: hasBorder
                  //todo
                  ? Border.all(
                      color: (borderColor ?? Theme.of(context).primaryColor),
                      width: borderWidth ?? 5.csw)
                  : null,
              borderRadius: BorderRadius.circular(borderRadius ?? 11.5),
            ),
            child: TextButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(
                    hasError ? Colors.grey : buttonBackgroundColor),
                overlayColor: MaterialStateProperty.all(
                    //todo
                    hasBorder
                        ? (borderColor ?? Theme.of(context).primaryColor)
                            .withOpacity(0.125)
                        : buttonOverlayColor),
              ),
              onPressed: hasError
                  ? null
                  : () {
                      if (!isLoading) {
                        onPressed();
                      }
                    },
              child: Padding(
                  padding: padding ??
                      EdgeInsets.symmetric(horizontal: 30.csw, vertical: 9.csh),
                  child: Row(
                    mainAxisAlignment: mainAxisAlignment,
                    children: [
                      if (firstIconAsset != null)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 5.0),
                          child: SizedBox(
                            height: firstIconHeight != null
                                ? firstIconHeight!.csh
                                : null,
                            width: firstIconWidth != null
                                ? firstIconWidth!.csw
                                : null,
                            child: Image.asset(
                              firstIconAsset!,
                              height: firstIconHeight != null
                                  ? firstIconHeight!.csh
                                  : null,
                              width: firstIconWidth != null
                                  ? firstIconWidth!.csw
                                  : null,
                              color: firstIconColor,
                            ),
                          ),
                        ),
                      if (firstIconPath != null)
                        SizedBox(
                          height:
                              firstIconHeight ?? firstIconHeightPercentage.csh,
                          width: firstIconWidth ?? firstIconWidthPercentage.csw,
                          child: ClipRRect(
                            clipBehavior: Clip.antiAlias,
                            borderRadius:
                                BorderRadius.circular(firstIconPathRadius),
                            child: CommonImage(
                                size: firstIconHeight ??
                                    firstIconHeightPercentage.csw,
                                fit: firstIconBoxFit,
                                color: firstIconColor,
                                imageUrl: firstIconPath!),
                          ),
                        ),
                      if (firstIconWidget != null) firstIconWidget!,
                      if (firstIconPath != null)
                        SizedBox(width: firstIconSpaceWidth?.csw ?? 5),
                      if (isTextExpanded) Expanded(child: textWidget()),
                      if (!isTextExpanded) textWidget(),
                      if (lastIconPath != null && !isTextExpanded)
                        const Spacer(),
                      if (lastIconPath != null)
                        SizedBox(
                          height:
                              lastIconHeight ?? lastIconHeightPercentage.csw,
                          width: lastIconWidth ?? lastIconWidthPercentage.csw,
                          child: CommonImage(
                              size: lastIconHeight ??
                                  lastIconHeightPercentage.csw,
                              color: lastIconColor,
                              imageUrl: lastIconPath!),
                        ),
                    ],
                  )

                  // : Center(
                  //     child: SpinKitCircle(
                  //       color: Colors.white,
                  //       size: getRelativeWidth(0.07),
                  //     ),
                  //   ),
                  ),
            ))
        : Container(
            margin: EdgeInsets.symmetric(
              horizontal: marginWidth.csw,
              vertical: marginHeight.csh,
            ),
            child: LinearProgressIndicator(
              //todo
              valueColor:
                  AlwaysStoppedAnimation(Theme.of(context).primaryColor),
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.4),
            ),
          );
  }

  Widget textWidget() {
    return Text(
      text!,
      textAlign: textAlign,
      style: TextStyle(
        height: 1,
        fontSize: fontSize ?? 15.sp,
        color: textColor,
        fontWeight: fontWeight ?? FontWeight.w500,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
    );
  }
}
