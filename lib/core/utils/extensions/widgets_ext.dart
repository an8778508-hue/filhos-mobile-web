import 'package:flutter/material.dart';

extension SplashEffect on Widget {
  Widget splash(
          {Function()? onPressed,
          bool active = true,
          BorderRadiusGeometry borderRadius =
              const BorderRadius.all(Radius.circular(11.5))}) =>
      Stack(
        children: <Widget>[
          this,
          if (active) ...[
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 0,
              child: TextButton(
                onPressed: onPressed,
                style: ButtonStyle(
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: borderRadius,
                    ),
                  ),
                  overlayColor: MaterialStateColor.resolveWith(
                      (states) => Colors.grey.withOpacity(0.2)),
                ),
                child: Container(
                    decoration: BoxDecoration(borderRadius: borderRadius)),
              ),
            )
          ]
        ],
      );

  Widget addPadding({required EdgeInsetsGeometry padding}) => Padding(
        padding: padding,
        child: this,
      );
}
