
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/network/network_models.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/add_form/add_form_screen.dart';
import 'package:escola/features/add_form/models/params.dart';
import 'package:escola/features/settings/my_children/repo/my_children_repo.dart';

class AddMedicineRepo {
  final AddFormType addFormType;
  final NetworkClientRepository networkClient;
  final MyChildrenRepo myChildrenRepo;

  const AddMedicineRepo(this.addFormType, this.networkClient, this.myChildrenRepo);
  final String itemsEndpoint = 'parent/medicines/items/types';

  Future<Either<Failure, List<Map>>> fetchMedicineFields() async {
    return await networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.get,
        url: itemsEndpoint,
      ),
      onSuccess: (json) {
        return List<dynamic>.of(json['data']).map((e) => e as Map).cast<Map>().toList();
      },
    );
  }

  // Future<Either<Failure, void>> saveMedicine(Map<String, CreateFormParams> form, [String? id]) async {
  //   // debugPrint(getPrettyJSONString(form));
  //   for (final entry in form.entries) {
  //     debugPrint('${entry.key}: ${entry.value.value} (${entry.value.value.runtimeType})');
  //   }
  //
  //   final String endpoint= id != null ? '/parent/medicines/$id' : '/parent/medicines';
  //
  //
  //   return await networkClient.handleRequest(
  //     NetworkRequest(
  //       method: HttpMethod.post,
  //       url: endpoint,
  //       body: FormData.fromMap(
  //           {
  //             // if (id != null) '_method': 'PUT',
  //             for (final entry in form.entries)
  //               if (entry.value.value is List<UploadFileParam>)
  //               //     for (int i = 0; i < (entry.value.value as List<UploadFileParam>).length; i++)
  //               //       entry.key == 'images' ? '${entry.key}[$i]' : '${entry.key}[$i]':
  //               //       ((entry.value.value as List<UploadFileParam>)[i].url.startsWith('http')
  //               // ? (entry.value.value as List<UploadFileParam>)[i].url
  //               // : await MultipartFile.fromFile((entry.value.value as List<UploadFileParam>)[i].url))
  //               // else
  //                 for (int i = 0; i < (entry.value.value as List<UploadFileParam>).length; i++)
  //                   '${entry.key}[$i]': {
  //                     if (validString((entry.value.value as List<UploadFileParam>)[i].id))
  //                       'id': (entry.value.value as List<UploadFileParam>)[i].id,
  //                     'url': (entry.value.value as List<UploadFileParam>)[i].url.startsWith('http')
  //                         ? (entry.value.value as List<UploadFileParam>)[i].url
  //                         : await MultipartFile.fromFile((entry.value.value as List<UploadFileParam>)[i].url),
  //                   }
  //               else if (entry.value.value is List)
  //                 entry.key: [
  //                   for (final item in (entry.value.value as List))
  //                     if (item is! UploadFileParam) item
  //                 ]
  //               else if (entry.value.value is UploadFileParam)
  //                   entry.key: {
  //                     if (validString((entry.value.value as UploadFileParam).id))
  //                       'id': (entry.value.value as UploadFileParam).id,
  //                     'url': (entry.value.value as UploadFileParam).url.startsWith('http')
  //                         ? (entry.value.value as UploadFileParam).url
  //                         : await MultipartFile.fromFile((entry.value.value as UploadFileParam).url),
  //                   }
  //                 else
  //                   entry.key: entry.value.value,
  //           }.map((key, value) => MapEntry(
  //               value is List
  //                   ?'$key[]'
  //                   : key,
  //               value))),
  //     ),
  //   );
  // }

  Future<Either<Failure, void>> saveMedicine(Map<String, CreateFormParams> form, [String? id]) async {
    final String endpoint = id != null ? '/parent/medicines/$id' : '/parent/medicines';

    final Map<String, dynamic> formDataMap = {};

    for (final entry in form.entries) {
      final key = entry.key;
      final value = entry.value.value;

      // if (key == 'images' && value is List<UploadFileParam>) {
      //   final isAllNetwork = value.every((file) => file.url.startsWith('https'));
      //
      //   if (isAllNetwork) {
      //     // Send images as an array of objects with URLs and IDs
      //     formDataMap['images'] = [
      //       for (final file in value)
      //         {
      //           'url': file.url,
      //           'id': file.id,
      //         }
      //     ];
      //   } else {
      //     // Send actual files as multipart
      //     for (int i = 0; i < value.length; i++) {
      //       final file = value[i];
      //       final fileKey = 'images[$i]';
      //       formDataMap[fileKey] = await MultipartFile.fromFile(file.url);
      //     }
      //   }
      // } else if (value is List) {
      //   // Handle other list fields if needed
      //   formDataMap['$key[]'] = value;
      // } else {
      //   // Simple key/value pairs
      //   formDataMap[key] = value;
      // }
      if (key == 'images' && value is List<UploadFileParam>) {
        // Handle each image individually based on its source
        for (int i = 0; i < value.length; i++) {
          final file = value[i];
          final fileKey = 'images[$i]';

          if (file.url.startsWith('http')) {
            // For network images, include URL and ID as an object
            formDataMap[fileKey] = {
              'url': file.url,
              if (validString(file.id)) 'id': file.id,
            };
          } else {
            // For local files, create a multipart file
            formDataMap[fileKey] = await MultipartFile.fromFile(file.url);
          }
        }
      } else if (value is List) {
        // Handle other list fields
        formDataMap['$key[]'] = value;
      } else {
        // Simple key/value pairs
        formDataMap[key] = value;
      }
    }

    return await networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.post,
        url: endpoint,
        body: FormData.fromMap(formDataMap),
      ),
    );
  }

}
