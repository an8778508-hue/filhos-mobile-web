import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/features/diary/models/child_model.dart';
import 'package:escola/features/gallery/model/gallery_list_model.dart';

class GalleryRepo {
  final NetworkClientRepository networkClient;

  GalleryRepo({required this.networkClient});

  Future<Either<Failure, List<GalleryListModel>>> getGallery() async {
    await Future.delayed(const Duration(seconds: 1));
    return Right(
      [
        for (int i = 0; i < 3; i++)
          GalleryListModel(
            childModel: ChildModel(
              id: 0,
              name: "Osama",
              age: '12 years old',
              classRoom: '2/1',
              parent: null,
              avatar: 'https://cataas.com/cat/says/$i',
            ),
            images: [
              for (int j = 0; j < 10; j++) 'https://cataas.com/cat/says/$i$j',
            ],
          ),
      ],
    );
    // return await networkClient.handleRequest(
    //   const NetworkRequest(
    //     method: HttpMethod.get,
    //     url: 'gallery',
    //   ),
    //   onSuccess: (json) {
    //     final data = <GalleryListModel>[];
    //     for (final event in json['data']) {
    //       data.add(GalleryListModel.fromJson(event));
    //     }
    //     return data;
    //   },
    // );
  }
  Future<Either<Failure, List<String>>> getGalleryImages(String id) async {
    await Future.delayed(const Duration(seconds: 1));
    return Right(
      [
        for (int j = 0; j < 10; j++) 'https://cataas.com/cat/says/$j',

      ],
    );
    // return await networkClient.handleRequest(
    //   const NetworkRequest(
    //     method: HttpMethod.get,
    //     url: 'gallery',
    //   ),
    //   onSuccess: (json) {
    //     final data = <GalleryListModel>[];
    //     for (final event in json['data']) {
    //       data.add(GalleryListModel.fromJson(event));
    //     }
    //     return data;
    //   },
    // );
  }
}
