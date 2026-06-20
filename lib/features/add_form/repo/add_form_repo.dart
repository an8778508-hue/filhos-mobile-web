import 'dart:convert';
import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/network/network_models.dart';
import 'package:escola/core/utils/safe_x.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/add_form/add_form_screen.dart';
import 'package:escola/features/add_form/models/add_form_model.dart';
import 'package:escola/features/add_form/models/collection_model.dart';
import 'package:escola/features/add_form/models/params.dart';
import 'package:escola/core/user/current_role.dart';
import 'package:escola/features/diary/models/child_model.dart';
import 'package:escola/features/settings/my_children/repo/my_children_repo.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class AddFormRepo {
  final AddFormType addFormType;
  final NetworkClientRepository networkClient;
  final MyChildrenRepo myChildrenRepo;

  const AddFormRepo(this.addFormType, this.networkClient, this.myChildrenRepo);

  Future<Either<Failure, AddFormFormModel>> fetchFields() async {
    switch (addFormType) {
      case AddFormType.medicine:
        final eventsForm = jsonDecode(await rootBundle.loadString('assets/medicines_fields.json'));
        if (isCurrentUserParent) {
          final f = await myChildrenRepo.getChildren(1);
          final children = f.fold((l) => <ChildModel>[], (r) => r);
          eventsForm['data'][0]['values'] = [
            ...children.map((e) => {'id': e.id, 'name': e.name})
          ];
        }
        return Right(AddFormFormModel.fromJson(eventsForm));
      case AddFormType.event:
        final eventsForm = jsonDecode(await rootBundle.loadString('assets/events_fields.json'));
        return Right(AddFormFormModel.fromJson(eventsForm));
      case AddFormType.announcement:
        final announcementsForm = jsonDecode(await rootBundle.loadString('assets/announcements_fields.json'));
        return Right(AddFormFormModel.fromJson(announcementsForm));
    }
  }

  Future<Either<Failure, Map<FormModel, CreateFormParams>>> fetchForm(String id) async {
    final String endpoint;
    switch (addFormType) {
      case AddFormType.medicine:
        endpoint = '/parent/medicines/$id';
      case AddFormType.event:
        endpoint = '';
      case AddFormType.announcement:
        endpoint = '';
    }

    final List<Either<Failure, Object>> f = await Future.wait([
      fetchFields(),
      networkClient.handleRequest(
        NetworkRequest(
          method: HttpMethod.get,
          url: endpoint,
        ),
        onSuccess: (json) {
          final data = json['data'];
          if (validMap(data)) {
            data as Map<String, dynamic>;
            final payload = data['payload'];
            if (validMap(payload)) {
              return payload as Map<String, dynamic>;
            }
          }
          return {};
        },
      ),
    ]);

    final fieldsResponse = f.first.fold((l) => null, (r) => r as AddFormFormModel);
    final payloadResponse = f.last.fold((l) => null, (r) => r as Map<String, dynamic>);

    if (fieldsResponse == null || payloadResponse == null) {
      return const Right({});
    }

    final List<FormModel> fields =
        fieldsResponse.fields.fold([], (p, c) => [...p, if (c is CollectionFormModel) ...c.items else c]);
    final Map<FormModel, CreateFormParams> result = {};
    for (final entry in payloadResponse.entries) {
      final field = fields.safeFirstWhere((e) => e.id == entry.key);
      if (field != null) {
        result[field] = CreateFormParams(
            type: field.type,
            value: field.type == FormType.attachment || field.type == FormType.uploadImage
                ? (entry.value as List).map((e) => UploadFileParam.fromJson(e)).toList()
                : field.type == FormType.counter
                    ? convertToDouble(entry.value)
                    : entry.value);
      }
    }
    return Right(result);
  }

  Future<Either<Failure, void>> saveForm(Map<String, CreateFormParams> form, [String? id]) async {
    // debugPrint(getPrettyJSONString(form));
    for (final entry in form.entries) {
      debugPrint('${entry.key}: ${entry.value.value} (${entry.value.value.runtimeType})');
    }

    final String endpoint;
    switch (addFormType) {
      case AddFormType.medicine:
        endpoint = id != null ? '/parent/medicines/$id' : '/parent/medicines';
      case AddFormType.event:
        endpoint = 'events/create';
      case AddFormType.announcement:
        // Base URL already includes `/api/v1/`; keep the path relative like every
        // other endpoint, otherwise it doubles to `/api/v1/api/v1/...`.
        endpoint = 'teacher/announcements';
    }

    // return Left(ServerFailure(message: 'test'));
    bool isEvent = addFormType == AddFormType.event;
    receiversKey(String key) => isEvent ? key : 'receivers[$key]';

    Map<String, dynamic>? eventMap;
    if (isEvent) {
      {
        final receivers = (form['receivers'] as CreateFormParams).value as Map;
        getList(String key) =>
            validateList(receivers[key]).any((element) => element == 'all') ? [] : validateList(receivers[key]);

        final children = getList('children');
        final classes = getList('class');
        final levels = getList('levels');
        final teachers = getList('teachers');
        final parents = getList('parents');
        final String? imageUrl = (form['image']?.value as List<UploadFileParam>).safeElementAt(0)?.url;

        eventMap = {
          if (children.isNotEmpty)
            for (int i = 0; i < children.length; i++) "audiences[child][$i]": "${children.toList()[i]}",
          if (classes.isNotEmpty)
            for (int i = 0; i < classes.length; i++) "audiences[class][$i]": "${classes.toList()[i]}",
          if (levels.isNotEmpty)
            for (int i = 0; i < levels.length; i++) "audiences[level][$i]": "${levels.toList()[i]}",
          if (teachers.isNotEmpty)
            for (int i = 0; i < teachers.length; i++) "audiences[teacher][$i]": "${teachers.toList()[i]}",
          if (parents.isNotEmpty)
            for (int i = 0; i < parents.length; i++) "audiences[parent][$i]": "${parents.toList()[i]}",
          if (validateList(receivers['parents']).any((element) => element == 'all')) "all_parents": 1,
          if (validateList(receivers['teachers']).any((element) => element == 'all')) "all_teachers": 1,
          "title": form['title']?.value,
          "description": form['description']?.value,
          "start_date":
              '${validateString(form['starting_date']?.value)} ${validateString(form['starting_time']?.value)}',
          "end_date": '${validateString(form['ending_date']?.value)} ${validateString(form['ending_time']?.value)}',
          "has_approval": form['has_approval']?.value,
          "has_payment": form['has_payment']?.value,
          "is_feature": form['is_feature']?.value ?? '0',
          "price": form['price']?.value,
          "price_for_all_children": form['price_for_all_children']?.value??'0',
          "payment_info": form['payment_info']?.value,
          "image": imageUrl == null ? null : await MultipartFile.fromFile(imageUrl),
          if ((form['images']?.value) is List)
            for (int i = 0; i < (form['images']?.value as List).length; i++)
              "images[$i][url]":
                  await MultipartFile.fromFile(((form['images']?.value as List)[i] as UploadFileParam).url),
        };
        log('AddFormRepo.saveFormsaveForm ${(eventMap)}');
      }
    }

    return await networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.post,
        url: endpoint,
        body: FormData.fromMap(eventMap ??
            {
              if (id != null) '_method': 'PUT',
              for (final entry in form.entries)
                if (entry.key == 'receivers') ...{
                  receiversKey("children"): ((entry.value.value as Map)['children']),
                  receiversKey("teachers"): ((entry.value.value as Map)['teachers']),
                  receiversKey("parents"): ((entry.value.value as Map)['parents']),
                  receiversKey("classes"): ((entry.value.value as Map)['class']),
                  receiversKey("levels"): ((entry.value.value as Map)['levels']),
                } else if (entry.value.value is List<UploadFileParam>)
                  if (isEvent)
                    for (int i = 0; i < (entry.value.value as List<UploadFileParam>).length; i++)
                      entry.key == 'image' ? entry.key : '${entry.key}[$i]':
                          await MultipartFile.fromFile((entry.value.value as List<UploadFileParam>)[i].url)
                  else
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
                    ? isEvent
                        ? key
                        : '$key[]'
                    : key,
                value))),
      ),
    );
  }
}
