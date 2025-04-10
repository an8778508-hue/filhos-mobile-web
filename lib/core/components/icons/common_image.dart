import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:escola/core/components/icons/document_widget.dart';
import 'package:escola/core/components/loading/loading.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CommonImage extends StatelessWidget {
  final String? imageUrl;
  final String? fallBackImagePath;
  final Widget? loadingWidget, fallBackWidget;
  final Color? color;
  final String? package;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final bool isFile, isClickable, showLoading;
  final Widget? errorWidget;

  const CommonImage({
    super.key,
    required this.imageUrl,
    this.fallBackImagePath,
    this.color,
    double? size,
    double? width,
    double? height,
    this.fit,
    this.isFile = false,
    this.errorWidget,
    this.isClickable = false,
    this.package,
    this.loadingWidget,
    this.showLoading = false,
    this.fallBackWidget,
  })  : width = size ?? width,
        height = size ?? height;

  @override
  Widget build(BuildContext context) {
    String? imageUrl = stringNotNullOrEmpty(this.imageUrl) ? this.imageUrl : fallBackImagePath;
    if (!stringNotNullOrEmpty(imageUrl)) {
      return const SizedBox(
        width: 16,
        height: 16,
      );
    } else if (imageUrl!.endsWith('.pdf') || imageUrl.endsWith('.doc')) {
      return DocumentWidget(url: imageUrl);
    } else if (isFile) {
      return Image.file(
        File(imageUrl),
        fit: fit,
        width: width,
        height: height,
        color: color,
      );
    }
    bool network = imageUrl.startsWith('http');
    if (network && !imageUrl.endsWith('.svg')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        color: color,
        fit: fit,
        cacheKey: imageUrl.split('/').last,
        placeholder: (context, url) =>
            loadingWidget ??
            (showLoading
                ? SizedBox(width: width, height: height, child: const Center(child: Loading()))
                : const SizedBox()),
        errorWidget: (context, url, error) =>
            errorWidget ??
            (fallBackImagePath != null
                ? CommonImage(
                    imageUrl: fallBackImagePath!,
                    width: width,
                    height: height,
                    fit: fit,
                  )
                : const Icon(Icons.error)),
      );
    } else if (isAssetImage(imageUrl)) {
      return Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        color: color,
        package: package,
        errorBuilder: (context, obj, st) {
          return fallBackImagePath != null
              ? CommonImage(
                  imageUrl: fallBackImagePath,
                  fit: fit,
                  width: width,
                  height: height,
                )
              : Icon(Icons.error);
        },
      );
    } else if (imageUrl.endsWith('.svg')) {
      return network
          ? SvgPicture.network(imageUrl, width: width, color: color, height: height)
          : SvgPicture.asset(imageUrl,
              width: width,
              height: height,
              colorFilter: color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
              fit: fit ?? BoxFit.contain);
    }
    return fallBackImagePath != null
        ? CommonImage(
            imageUrl: fallBackImagePath,
            fit: fit,
            width: width,
            height: height,
          )
        : const SizedBox();
  }
}
