import 'dart:io';

import 'package:dio/dio.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:escola/core/components/loading/loading.dart';

class ShareWidget extends StatefulWidget {
  final List<String> media;
  final String? titleKey;

  const ShareWidget({
    super.key,
    required this.media,
    this.titleKey,
  });

  @override
  State<ShareWidget> createState() => _ShareWidgetState();
}

class _ShareWidgetState extends State<ShareWidget> {
  bool isSharing = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        _shareImage();
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 10.w,
          vertical: 20.h,
        ),
        child: Row(
          children: [
            if (isSharing) ...[
              SizedBox(
                width: 15.w,
                height: 15.w,
                child: const Loading(
                  color: Colors.white,
                ),
              )
            ] else ...[
              Icon(
                Icons.share_outlined,
                size: 16.w,
                color: widget.media.isEmpty ? Colors.grey : Colors.white,
              )
            ],
            SizedBox(width: 10.w),
            Text(
              (widget.titleKey ?? LocalizationKeys.share_selected).tr(context),
              style: TextStyle(
                color: widget.media.isEmpty ? Colors.grey : Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 15.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _shareImage() async {
    setState(() => isSharing = true);
    final pathes = await getImagePathes();
    setState(() => isSharing = false);

    final List<XFile> files = pathes.map((e) => XFile(e)).toList();
    // Share
    Share.shareXFiles(files);
  }

  Future<List<String>> getImagePathes() async {
    List<String> pathes = [];
    try {
      for (var i = 0; i < widget.media.length; i++) {
        final media = widget.media[i];
        final Response response = await Dio().get(
          media,
          options: Options(
            responseType: ResponseType.bytes,
          ),
        );
        final Directory directory = await getTemporaryDirectory();
        final ext = media.split('.').last;
        final file = File("${directory.path}/${DateTime.now().millisecondsSinceEpoch.toString()}.$ext");
        file.writeAsBytesSync(Uint8List.fromList(response.data));
        debugPrint('==> ${file.path}');
        pathes.add(file.path);
      }
      return pathes;
    } catch (e) {
      debugPrint("Error: $e");
      return [];
    }
  }
}
