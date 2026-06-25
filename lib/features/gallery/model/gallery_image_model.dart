import 'package:equatable/equatable.dart';
import 'package:escola/core/utils/valid_data.dart';

/// A single photo in a child's dedicated gallery album.
///
/// Mirrors the backend `GalleryResource`:
/// `{ id, image, caption, source, taken_at, child: {id, name}, created_at }`.
class GalleryImageModel extends Equatable {
  final int id;
  final String image;
  final String? caption;
  final String source;
  final String? takenAt;
  final int? childId;
  final String? childName;
  final String? createdAt;

  const GalleryImageModel({
    required this.id,
    required this.image,
    this.caption,
    this.source = 'standalone',
    this.takenAt,
    this.childId,
    this.childName,
    this.createdAt,
  });

  factory GalleryImageModel.fromJson(Map<String, dynamic> json) {
    final child = validMap<String, dynamic>(json['child']) ? json['child'] as Map<String, dynamic> : null;

    return GalleryImageModel(
      id: validateInt(json['id']),
      image: validateString(json['image']),
      caption: validString(json['caption']) ? json['caption'] as String : null,
      source: validateString(json['source'], 'standalone'),
      takenAt: validString(json['taken_at']) ? json['taken_at'] as String : null,
      childId: child != null ? validateInt(child['id']) : null,
      childName: child != null && validString(child['name']) ? child['name'] as String : null,
      createdAt: validString(json['created_at']) ? json['created_at'] as String : null,
    );
  }

  @override
  List<Object?> get props => [id, image, caption, source, takenAt, childId, childName, createdAt];
}
