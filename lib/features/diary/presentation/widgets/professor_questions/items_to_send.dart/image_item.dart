import 'package:escola/core/components/image/image_uploader.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/features/diary/models/questions_models/image_question.dart';
import 'package:escola/features/diary/models/tamplets/question_template.dart';
import 'package:escola/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:escola/features/diary/widgets/video_attachment_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ImagesItem extends StatefulWidget {
  final QuestionTemplate question;

  const ImagesItem({super.key, required this.question});

  @override
  State<ImagesItem> createState() => _ImagesItemState();
}

class _ImagesItemState extends State<ImagesItem> {
  /// Picked attachments are kept locally so an added video survives alongside
  /// any images and is re-dispatched as a single attachment list.
  final List<String> _images = [];
  String? _videoPath;

  QuestionTemplate get question => widget.question;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ImagesField(
          onChange: (images) {
            _images
              ..clear()
              ..addAll(images);
            _dispatch(context);
          },
          backgroundColor: context.colors.lightBackground,
          title: question.title ?? LocalizationKeys.attachments.tr(context),
          titleStyle: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w500, color: Colors.black),
        ),
        SizedBox(height: 12.h),
        VideoAttachmentPicker(
          selectedVideoPath: _videoPath,
          onVideoPicked: (path) {
            setState(() => _videoPath = path);
            _dispatch(context);
          },
          onRemove: () {
            setState(() => _videoPath = null);
            _dispatch(context);
          },
        ),
      ],
    );
  }

  List<String> get _attachments => [
        ..._images,
        if (_videoPath != null && _videoPath!.isNotEmpty) _videoPath!,
      ];

  void _dispatch(BuildContext context) {
    final attachments = _attachments;
    if (attachments.isEmpty) {
      context.read<DiaryBloc>().add(RemoveQuestion(questionId: question.id, categoryId: question.categoryId));
    } else {
      final imageQuestion = ImagesQuestion(
        id: question.id,
        label: question.title,
        images: attachments,
      );
      context.read<DiaryBloc>().add(AddQuetsion(question: imageQuestion, categoryId: question.categoryId));
    }
  }
}
