import 'dart:convert';
import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/network/network_models.dart';
import 'package:escola/core/utils/print.dart';
import 'package:escola/core/utils/safe_x.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/add_form/add_form_screen.dart';
import 'package:escola/features/add_form/models/add_form_model.dart';
import 'package:escola/features/add_form/models/collection_model.dart';
import 'package:escola/features/add_form/models/params.dart';
import 'package:escola/features/diary/models/child_model.dart';
import 'package:escola/features/settings/my_children/repo/my_children_repo.dart';
import 'package:escola/flavors/app_flavors.dart';
import 'package:escola/my_app.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

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
  Future<Either<Failure, void>> saveMedicine(Map<String, CreateFormParams> form, [String? id]) async {
    // debugPrint(getPrettyJSONString(form));
    for (final entry in form.entries) {
      debugPrint('${entry.key}: ${entry.value.value} (${entry.value.value.runtimeType})');
    }

    final String endpoint= id != null ? '/parent/medicines/$id' : '/parent/medicines';


    return await networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.post,
        url: endpoint,
        body: FormData.fromMap(
            {
              // if (id != null) '_method': 'PUT',
              for (final entry in form.entries)
                if (entry.value.value is List<UploadFileParam>)
              //     for (int i = 0; i < (entry.value.value as List<UploadFileParam>).length; i++)
              //       entry.key == 'images' ? '${entry.key}[$i]' : '${entry.key}[$i]':
              //       ((entry.value.value as List<UploadFileParam>)[i].url.startsWith('http')
              // ? (entry.value.value as List<UploadFileParam>)[i].url
              // : await MultipartFile.fromFile((entry.value.value as List<UploadFileParam>)[i].url))
                // else
                  for (int i = 0; i < (entry.value.value as List<UploadFileParam>).length; i++)
                    '${entry.key}[$i]': {
    if (validString((entry.value.value as List<UploadFileParam>)[i].id))
                        'id': (entry.value.value as List<UploadFileParam>)[i].id,
                      'url': (entry.value.value as List<UploadFileParam>)[i].url.startsWith('http')
                          ? (entry.value.value as List<UploadFileParam>)[i].url
                          : await MultipartFile.fromFile((entry.value.value as List<UploadFileParam>)[i].url),
                    }
                else if (entry.value.value is List)
                  entry.key: [
                    for (final item in (entry.value.value as List))
                      if (item is! UploadFileParam) item
                  ]
                else if (entry.value.value is UploadFileParam)
                    entry.key: {
                      if (validString((entry.value.value as UploadFileParam).id))
                        'id': (entry.value.value as UploadFileParam).id,
                      'url': (entry.value.value as UploadFileParam).url.startsWith('http')
                          ? (entry.value.value as UploadFileParam).url
                          : await MultipartFile.fromFile((entry.value.value as UploadFileParam).url),
                    }
                  else
                    entry.key: entry.value.value,
            }.map((key, value) => MapEntry(
                value is List
                    ?'$key[]'
                    : key,
                value))),
      ),
    );
  }

}
