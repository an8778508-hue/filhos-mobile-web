import 'package:escola/core/components/icons/common_image.dart';
import 'package:escola/core/components/image/photo_viewer.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/chat/models/message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:escola/core/components/loading/loading.dart';

class ImageMessage extends StatefulWidget {
  final Message message;
  const ImageMessage({super.key, required this.message});

  @override
  State<ImageMessage> createState() => _ImageMessageState();
}

class _ImageMessageState extends State<ImageMessage> {
  String? fileImage;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant ImageMessage oldWidget) {
    if (!isHttpLink(oldWidget.message.content)) {
      setState(() {
        fileImage = oldWidget.message.content;
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => PhotoViewer(
                    url: widget.message.content, tag: widget.message.content)));
      },
      child: SizedBox(
        width: 200.w,
        child: Stack(
          children: [
            Opacity(
                opacity: !isHttpLink(widget.message.content) ? 0.5 : 1,
                child: CommonImage(
                    isFile: !isHttpLink(widget.message.content),
                    imageUrl: widget.message.content,
                    fit: BoxFit.fill,
                    loadingWidget: fileImage != null
                        ? CommonImage(
                            isFile: true,
                            imageUrl: fileImage,
                            fit: BoxFit.fill,
                          )
                        : const Loading())),
            if (!isHttpLink(widget.message.content)) ...[
              const Positioned.fill(child: Center(child: Loading()))
            ],
          ],
        ),
      ),
    );
  }
}
