import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/network/network_models.dart';
import 'package:escola/features/gallery/model/gallery_image_model.dart';
import 'package:escola/features/gallery/model/gallery_list_model.dart';

class GalleryRepo {
  final NetworkClientRepository networkClient;

  GalleryRepo({required this.networkClient});

  static const int defaultPerPage = 15;

  /// Legacy aggregated gallery (grouped by child) used by the older
  /// `GalleryScreen`. Kept for backwards compatibility; the dedicated album
  /// flow uses [getChildGallery].
  Future<Either<Failure, List<GalleryListModel>>> getGallery() async {
    return networkClient.handleRequest(
      const NetworkRequest(
        method: HttpMethod.get,
        url: 'gallery',
      ),
      onSuccess: (json) {
        final data = <GalleryListModel>[];
        for (final item in (json['data'] as List? ?? const [])) {
          if (item is Map<String, dynamic>) {
            data.add(GalleryListModel.fromJson(item));
          }
        }
        return data;
      },
    );
  }

  /// Fetch a single child's dedicated photo album (paginated).
  ///
  /// Hits `parent/children/{childId}/gallery` for the parents flavor and
  /// `teacher/children/{childId}/gallery` for the teachers flavor.
  Future<Either<Failure, List<GalleryImageModel>>> getChildGallery(
    int childId, {
    int page = 1,
    int perPage = defaultPerPage,
    bool asTeacher = false,
  }) async {
    final prefix = asTeacher ? 'teacher' : 'parent';
    return networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.get,
        url: '$prefix/children/$childId/gallery',
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      ),
      onSuccess: (json) {
        final data = <GalleryImageModel>[];
        for (final item in (json['data'] as List? ?? const [])) {
          if (item is Map<String, dynamic>) {
            data.add(GalleryImageModel.fromJson(item));
          }
        }
        return data;
      },
    );
  }

  /// Teacher uploads a photo to a child's album. `imagePath` is a local file path.
  Future<Either<Failure, GalleryImageModel>> uploadPhoto({
    required int childId,
    required String imagePath,
    String? caption,
  }) async {
    final formData = FormData.fromMap({
      'child_id': childId,
      if (caption != null && caption.isNotEmpty) 'caption': caption,
      'image': await MultipartFile.fromFile(imagePath, filename: imagePath.split('/').last),
    });

    return networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.post,
        url: 'teacher/gallery',
        body: formData,
      ),
      onSuccess: (json) => GalleryImageModel.fromJson(json['data']),
    );
  }

  /// Legacy: flat list of image urls for a child, consumed by the older
  /// `GalleryImagesScreen`. Backed by the same real endpoint as
  /// [getChildGallery] but flattened to urls.
  Future<Either<Failure, List<String>>> getGalleryImages(String id) async {
    final childId = int.tryParse(id) ?? 0;
    final result = await getChildGallery(childId);
    return result.map((list) => list.map((e) => e.image).toList());
  }
}
