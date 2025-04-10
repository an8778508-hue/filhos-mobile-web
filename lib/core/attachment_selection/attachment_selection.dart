import 'package:escola/core/attachment_selection/attachment_src.dart';
import 'package:escola/core/attachment_selection/show_attachment_selection_bottomsheet.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

Future<List<String>> pickAttachments(BuildContext context, {bool multiple = true}) async {
  final result = await showAttachmentSelectionBottomSheet(context);
  if (!context.mounted) {
    return [];
  }
  if (result != null) {
    switch (result) {
      case AttachmentSrc.gallery:
        return await pickFile(context, multiple: multiple);
      case AttachmentSrc.camera:
        return await pickImage(context);
      default:
        return [];
    }
  }
  return [];
}

Future<List<String>> pickFile(BuildContext context, {bool multiple = true}) async {
  final result = await FilePicker.platform.pickFiles(allowMultiple: multiple);
  final files = result?.files.where((e) => validString(e.path)).toList();
  if (validList(files)) {
    return files!.map((e) => e.path).where((e) => validString(e)).cast<String>().toList();
  }
  return [];
}

Future<List<String>> pickImage(BuildContext context) async {
  final result = await ImagePicker().pickImage(source: ImageSource.camera);
  if (result != null) {
    return [result.path];
  }
  return [];
}

Future<List<String>> pickVideo(BuildContext context) async {
  final result = await ImagePicker().pickVideo(source: ImageSource.camera);
  if (result != null) {
    return [result.path];
  }
  return [];
}

Future<List<String>> pickImagesAndVideos(
  BuildContext context,
) async {
  final result = await showAttachmentSelectionBottomSheet(context);
  if (!context.mounted) {
    return [];
  }
  if (result != null) {
    if (result == AttachmentSrc.gallery) {
      return await pickGallery(context);
    } else if (result == AttachmentSrc.camera) {
      final imageVideoResult = await showAttachmentSelectionBottomSheet(context, imageAndVideoOption: true);
      if (imageVideoResult != null && context.mounted) {
        if (imageVideoResult == AttachmentSrc.image) {
          return await pickImage(context);
        } else if (imageVideoResult == AttachmentSrc.video) {
          return await pickVideo(context);
        }
      }
    }
  }
  return [];
}

Future<List<String>> pickGallery(BuildContext context) async {
  final result = await ImagePicker().pickMultipleMedia();
  if (validList(result)) {
    return result.map((e) => e.path).where((e) => validString(e)).cast<String>().toList();
  }
  return [];
}
