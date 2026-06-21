import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:escola/core/components/icons/document_widget.dart';
import 'package:escola/core/components/loading/loading.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
      // Graceful fallback shown when a network image fails to load. Prefer an
      // explicit [errorWidget], then a [fallBackImagePath] image, and only as a
      // last resort a neutral placeholder (never the bare red error "!" icon).
      Widget buildErrorFallback() {
        if (errorWidget != null) return errorWidget!;
        if (fallBackImagePath != null) {
          return CommonImage(
            imageUrl: fallBackImagePath!,
            width: width,
            height: height,
            fit: fit,
          );
        }
        return _ImageFallback(width: width, height: height);
      }

      Widget buildPlaceholder() =>
          loadingWidget ??
          (showLoading
              ? SizedBox(width: width, height: height, child: const Center(child: Loading()))
              : SizedBox(width: width, height: height));

      // On web `cached_network_image` loads bytes over XHR, which is blocked by
      // CORS for cross-origin hosts (the config images live on
      // platform.filhos.app / disney.filhos.app). `Image.network` renders such
      // images via the browser's own `<img>` pipeline and gives us an
      // errorBuilder, so failures degrade to a fallback instead of a red icon.
      if (kIsWeb) {
        return Image.network(
          imageUrl,
          width: width,
          height: height,
          color: color,
          fit: fit,
          // With the CanvasKit/Skwasm web renderer, a cross-origin image whose
          // host doesn't send CORS headers (platform.filhos.app /
          // disney.filhos.app) can't be decoded onto the canvas and would error.
          // `fallback` makes Flutter render it via a plain HTML <img>, which is
          // not subject to that restriction, so the image still displays.
          webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
          errorBuilder: (context, error, stackTrace) => buildErrorFallback(),
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : buildPlaceholder(),
        );
      }

      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        color: color,
        fit: fit,
        cacheKey: imageUrl.split('/').last,
        placeholder: (context, url) => buildPlaceholder(),
        errorWidget: (context, url, error) => buildErrorFallback(),
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
              : _ImageFallback(width: width, height: height);
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

/// Neutral placeholder rendered when an image can't be displayed (network
/// failure, CORS block on web, missing asset). Replaces the bare red
/// `Icon(Icons.error)` "!" that used to leak into cards and onboarding.
class _ImageFallback extends StatelessWidget {
  final double? width;
  final double? height;

  const _ImageFallback({this.width, this.height});

  @override
  Widget build(BuildContext context) {
    final double iconSize = () {
      final dims = [width, height].whereType<double>();
      if (dims.isEmpty) return 24.0;
      return dims.reduce((a, b) => a < b ? a : b).clamp(16.0, 48.0);
    }();
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      color: Colors.black.withValues(alpha: 0.04),
      child: Icon(
        Icons.image_not_supported_outlined,
        size: iconSize,
        color: Colors.black26,
      ),
    );
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
