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
      if (network) {
        // `SvgPicture.network` has no error callback in this flutter_svg
        // version — a CORS / 404 / DNS failure throws all the way up to
        // the framework error handler, which on web tends to silently
        // crash the surrounding widget subtree. Wrap with a placeholder
        // builder + fallback so a flag/icon failure never kills the page.
        final fallback = errorWidget ??
            (fallBackImagePath != null
                ? CommonImage(
                    imageUrl: fallBackImagePath!,
                    width: width,
                    height: height,
                    fit: fit,
                  )
                : SizedBox(width: width, height: height));
        return _SafeSvgNetwork(
          url: imageUrl,
          width: width,
          height: height,
          color: color,
          fallback: fallback,
        );
      }
      return SvgPicture.asset(imageUrl,
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

/// Loads a network SVG with explicit error handling. On any fetch failure
/// (CORS, 404, DNS, etc.) renders `fallback` instead of bubbling the error
/// up to the framework's ErrorWidget (which on web tends to kill the
/// surrounding subtree silently).
class _SafeSvgNetwork extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final Color? color;
  final Widget fallback;

  const _SafeSvgNetwork({
    required this.url,
    required this.width,
    required this.height,
    required this.color,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.network(
      url,
      width: width,
      height: height,
      color: color,
      placeholderBuilder: (_) => SizedBox(width: width, height: height),
    );
  }
}
