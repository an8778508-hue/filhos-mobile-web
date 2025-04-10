import 'package:escola/core/utils/extensions/widgets_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:escola/features/chat/presentation/bloc/images_message_bloc.dart';
import 'package:escola/features/chat/presentation/styles/chat_styles.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

class FileIcon extends StatelessWidget {
  const FileIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.all(4.w),
      child: Icon(Icons.file_present,
          color: ChatColors.actionIconsColor, size: 25.w),
    ).splash(onPressed: () async {
      try {
        final result = await FilePicker.platform.pickFiles();
        final pickedFiles =
            result?.files.where((e) => validString(e.path)).toList();
        if (pickedFiles == null || pickedFiles.isEmpty) return;
        List<XFile> fileToSend = [];
        for (var i = 0; i < pickedFiles.length; i++) {
          final pickedFile = pickedFiles[i];
          if (pickedFile.path != null) {
            fileToSend.add(XFile(pickedFile.path!));
          }
        }
        context.read<ImagesMessageBloc>().add(AddImages(images: fileToSend));
      } catch (e) {}
    });
  }
}
