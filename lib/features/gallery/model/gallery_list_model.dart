import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/diary/models/child_model.dart';

class GalleryListModel {
  final ChildModel? childModel;
  final List<String> images;

  const GalleryListModel({
    required this.childModel,
    required this.images,
  });

  factory GalleryListModel.fromJson(Map<String, dynamic> json) => GalleryListModel(
        childModel: validateDataModel(json['child'], (e) => ChildModel.fromJson(e)),
        images: validateList(json['images']),
      );
}
