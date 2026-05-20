import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

chooseImage({
  required ImageSource imageSource,
  required BuildContext context,
  required void Function(Uint8List, XFile) onFinish,
}) async {
  debugPrint('account update choose image');
  try {
    final XFile? value = await ImagePicker().pickImage(source: imageSource);
    debugPrint('account update choose image pickedImage');
    if (value == null) return;
    if (!context.mounted) return;
    cropResize(
      pickedImage: value,
      context: context,
      onFinish: onFinish,
      source: imageSource,
    );
  } catch (e) {}
}

Future<void> cropResize({required XFile pickedImage, required BuildContext context, required void Function(Uint8List, XFile) onFinish, source}) async {
  final controller = CropController();
  final image = await pickedImage.readAsBytes();
  if (!context.mounted) return;
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: Container(
                  color: context.colors.textColor,
                  margin: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height / 12),
                  child: Crop(
                    controller: controller,
                    image: image,
                    // aspectRatio: 1 / 1,
                    onCropped: (CropResult value) {
                      switch (value) {
                        case CropSuccess():
                          Navigator.of(context).pop();
                          onFinish(value.croppedImage, pickedImage);
                        case CropFailure():
                      }
                    },
                  ),
                ),
              ),
              SizedBox(
                height: 60,
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        controller.crop();
                      }, // splashColor: Colors.white,
                      child: Text(
                        LocalizationKeys.ok.tr(context),
                        style: TextStyle(color: context.colors.background),
                      ),
                    ),
                  ),
                  Expanded(
                    child: MaterialButton(
                      onPressed: () {
                        Navigator.pop(context);
                      }, // ImagePicker().pickImage(source: source),
                      splashColor: context.colors.background,
                      child: Text(
                        LocalizationKeys.cancel.tr(context),
                        style: TextStyle(color: context.colors.background),
                      ),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return;
}
