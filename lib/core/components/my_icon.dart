// ignore_for_file: deprecated_member_use

import 'package:escola/core/utils/icon_mappers/fa_mapper.dart';
import 'package:escola/core/utils/icon_mappers/icon_utils.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:line_icons/line_icons.dart';

const imgExts = [
  'png',
  'jpg',
  'jpeg',
  'gif',
];

const svgExts = [
  'webp',
  'svg',
];

class MyIcon extends StatelessWidget {
  final String icon;
  final Color? color;
  final double? size;
  final BlendMode? colorBlendMode;

  const MyIcon(
    this.icon, {
    super.key,
    this.color,
    this.size,
    this.colorBlendMode,
  });

  MyIcon.native(
    IconData icon, {
    super.key,
    this.color,
    this.size,
    this.colorBlendMode,
  }) : icon = icon.codePoint.toString();

  @override
  Widget build(BuildContext context) {
    if (!validString(icon)) {
      return SizedBox(
        width: size,
        height: size,
      );
    }

    bool network = icon.startsWith('http');

    bool endsWithImgExt = imgExts.any((e) => icon.endsWith('.$e'));
    bool endsWithSvgExt = svgExts.any((e) => icon.endsWith('.$e'));

    final params = Uri.tryParse(icon)?.queryParameters;
    bool hasImgExtAsQueryParam = (params?.containsKey('ext') != true) ? false : imgExts.any((e) => params?['ext'] == e);
    bool hasSvgExtAsQueryParam = (params?.containsKey('ext') != true) ? false : svgExts.any((e) => params?['ext'] == e);

    bool isImg = endsWithImgExt || hasImgExtAsQueryParam;
    bool isSvg = endsWithSvgExt || hasSvgExtAsQueryParam;

    if (isImg) {
      if (network) {
        return Image.network(
          icon,
          width: size,
          height: size,
          color: color,
          colorBlendMode: colorBlendMode,
        );
      } else {
        return Image.asset(
          icon,
          width: size,
          height: size,
          color: color,
          colorBlendMode: colorBlendMode,
        );
      }
    }
    if (isSvg) {
      if (network) {
        return SvgPicture.network(
          icon,
          width: size,
          height: size,
          color: color,
          colorBlendMode: colorBlendMode ?? BlendMode.srcIn,
        );
      } else {
        return SvgPicture.asset(
          icon,
          width: size,
          height: size,
          color: color,
          colorBlendMode: colorBlendMode ?? BlendMode.srcIn,
        );
      }
    }
    final isNative = icon.startsWith('material');
    final isFontAwesome = icon.startsWith('fa');
    final isLineIcons = icon.startsWith('line');

    final iconName = replaceIcon(icon);

    if (isFontAwesome) {
      return FaIcon(
        faMap[iconName],
        color: color,
        size: size,
      );
    }
    if (isLineIcons) {
      return Icon(
        LineIcons.byName(iconName),
        color: color,
        size: size,
      );
    }
    if (isNative) {
      final iconData = int.tryParse(iconName);
      if (iconData != null) {
        return Icon(
          IconData(iconData, fontFamily: 'MaterialIcons'),
          color: color,
          size: size,
        );
      }
    }
    return SizedBox(
      width: size,
      height: size,
    );
  }
}
