import 'package:escola/core/utils/extensions/widgets_ext.dart';
import 'package:escola/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:escola/features/chat/presentation/bloc/images_message_bloc.dart';
import 'package:escola/features/chat/presentation/styles/chat_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/attachment_selection/attachment_selection.dart';

class CameraIcon extends StatelessWidget {
  const CameraIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.all(4.w),
      child: Icon(Icons.camera_alt_outlined,
          color: ChatColors.actionIconsColor, size: 25.w),
    ).splash(onPressed: () async {
      // final XFile? file =
      //     await ImagePicker().pickImage(source: ImageSource.camera);
      // if (file != null) {
      //   context.read<ImagesMessageBloc>().add(AddImages(images: [file]));
      // }
      final List<String> files = await pickAttachments(context);
      if (files.isNotEmpty) {
        context.read<ImagesMessageBloc>().add(
          AddImages(images: files.map((path) => XFile(path)).toList()),
        );
      }
    });
  }
}
