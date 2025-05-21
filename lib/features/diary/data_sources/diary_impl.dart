import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/network/network_models.dart';
import 'package:escola/features/diary/data_sources/diary_repo.dart';
import 'package:escola/features/diary/models/activities.dart';
import 'package:escola/features/diary/models/child_menu_item.dart';
import 'package:escola/features/diary/models/question_category.dart';
import 'package:escola/features/diary/models/questions_models/question.dart';
import 'package:escola/features/diary/models/questions_models/select_question.dart';
import 'package:escola/features/diary/models/school_item.dart';
import 'package:escola/features/diary/models/tamplets/question_category_template.dart';

class DiaryImpl extends DiaryRepo {
  final NetworkClientRepository networkClient;

  DiaryImpl({required this.networkClient});

  @override
  Future<Either<Failure, List<Activity>>> getActivities({required DateTime dateTime, required int? childId}) async {
    final queryParameters = {
      'date': dateTime.toIso8601String(),
      if (childId != null) 'child_id': childId.toString(),
    };

    return await networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.get,
        url: activitiesEndpoint,
        queryParameters: queryParameters,
      ),
      onSuccess: (json) {
        final activities = <Activity>[];
        // for(int index = 0; index < json['data'].length; index++) {
        //   if(index == json['data'].length - 1) {
        //   activities.add(Activity.fromJson(json['data'][index]));
        //   }
        // }
        //
        for (final activity in json['data']) {
          activities.add(Activity.fromJson(activity));
          activities.sort((a, b) => b.date!.compareTo(a.date!));
        }

        return activities;
      },
    );
  }

  @override
  Future<Either<Failure, List<QuestionCategoryTemplate>>> getCategoryTemplats({
    required DateTime dateTime,
    required int? childId,
    bool filterAttendance = false,
    bool filterMedia = false,
  }) async {
    return await networkClient.handleRequest(
      NetworkRequest(method: HttpMethod.get, url: questionsDataEndpoint),
      onSuccess: (json) {
        var categories = <QuestionCategoryTemplate>[];
        for (final category in json['data']) {
          categories.add(QuestionCategoryTemplate.fromJson(category));
        }

        if (filterAttendance) {
          categories = categories.where((e) => e.type == 'attendence').toList();
        }
        if (filterMedia) {
          categories = categories.where((e) => e.questionTamplets.any((e) => e.type == QuestionType.image)).toList();
          // adjust categories to have only images questions using copy with
          for (var i = 0; i < categories.length; i++) {
            categories[i] = categories[i].copyWith(
              questionTamplets: categories[i].questionTamplets.where((e) => e.type == QuestionType.image).toList(),
            );
          }
        }

        return categories;
      },
    );
  }

  getSelectedItemValue(Question question) {
    if (question.value is List) {
      final list = question.value as List;
      return list.map((e) => getValue(e)).toList();
    }
    return [getValue(question.value)];
  }

  getValue(dynamic value) {
    if (value is SelectItem) {
      return (value as SelectItem).value;
    }
    return value;
  }
// @override
//   Future<Either<Failure, void>> sendQuestions({
//     required List<QuestionCategory> categories,
//     required SchoolItem item,
//     required String teacherId,
//   }) async {
//     final answers = [];
//     for (final category in categories) {
//       for (final question in category.questions!) {
//         print('DiaryImpl.sendQuestions 1 $question');
//         answers.add({
//           'timeline_category_id': category.id.toString(),
//           'id': question.id.toString(),
//           if (question.type != QuestionType.image) 'metadata': [question.toJson()],
//           "type": category.type,
//           "is_image": question.type == QuestionType.image ? 1.toString() : 0.toString(),
//           if (category.statusType != null) "type_status": category.statusType,
//           'value': getSelectedItemValue(question),
//         });
//       }
//     }
//     final body = {
//       "typeable_type": _getTypeableType(item),
//       "typeable_id": item.type == SchoolItemType.allChildType ? null : item.id,
//       if (item.type == SchoolItemType.level) "level_id": item.id.toString(),
//       if (item.type == SchoolItemType.classType) "class_id": item.id.toString(),
//       if (item.type == SchoolItemType.childType) "child_id": item.id.toString(),
//       'fields': answers,
//     };
//
//     return await networkClient.handleRequest(
//       NetworkRequest(
//         method: HttpMethod.post,
//         url: sendQuestionsEndpoint,
//         body: FormData.fromMap(body),
//       ),
//       onSuccess: (json) {},
//     );
//   }
//   @override
//   Future<Either<Failure, void>> sendQuestions({
//     required List<QuestionCategory> categories,
//     required SchoolItem item,
//     required String teacherId,
//   }) async {
//     final formData = FormData();
//
//     // Add general fields
//     formData.fields.addAll([
//       MapEntry("typeable_type", _getTypeableType(item)?? "child"),
//       if (item.type == SchoolItemType.level)
//         MapEntry("level_id", item.id.toString()),
//       if (item.type == SchoolItemType.classType)
//         MapEntry("class_id", item.id.toString()),
//       if (item.type == SchoolItemType.childType)
//         MapEntry("child_id", item.id.toString()),
//       if (item.type != SchoolItemType.allChildType)
//         MapEntry("typeable_id", item.id.toString()),
//     ]);
//
//     // Add questions and file uploads
//     int fieldIndex = 0;
//     for (final category in categories) {
//       for (final question in category.questions!) {
//         final baseKey = 'fields[$fieldIndex]';
//
//         formData.fields.addAll([
//           MapEntry("$baseKey[timeline_category_id]", category.id.toString()),
//           MapEntry("$baseKey[id]", question.id.toString()),
//           MapEntry("$baseKey[type]", category.type?? "question"),
//           MapEntry("$baseKey[is_image]",
//               question.type == QuestionType.image ? "1" : "0"),
//           if (category.statusType != null)
//             MapEntry("$baseKey[type_status]", category.statusType!),
//           if (question.type != QuestionType.image)
//             MapEntry("$baseKey[metadata]",
//                 jsonEncode([question.toJson()])), // as a string
//         ]);
//
//         final value = getSelectedItemValue(question);
//         if (question.type == QuestionType.image) {
//           debugPrint('11111111111111111111111111');
//           for (final file in value) {
//             formData.files.add(MapEntry("$baseKey[value][]", file)); // ✅ key with []
//           }
//           debugPrint('222222222222222222222222222');
//         } else {
//           formData.fields.add(MapEntry("$baseKey[value]", value.toString()));
//         }
//         // if (question.type == QuestionType.image && value is List<MultipartFile>) {
//         //   for (final file in value) {
//         //     formData.files.add(MapEntry("$baseKey[value][]", file)); // ✅ key with []
//         //   }
//         // } else {
//         //   formData.fields.add(MapEntry("$baseKey[value]", value.toString()));
//         // }
//
//         fieldIndex++;
//       }
//     }
//
//     return await networkClient.handleRequest(
//       NetworkRequest(
//         method: HttpMethod.post,
//         url: sendQuestionsEndpoint,
//         body: formData,
//       ),
//       onSuccess: (json) {},
//     );
//   }
  @override
  Future<Either<Failure, void>> sendQuestions({
    required List<QuestionCategory> categories,
    required SchoolItem item,
    required String teacherId,
  }) async {
    final formData = FormData();

    // Add general fields
    formData.fields.addAll([
      MapEntry("typeable_type", _getTypeableType(item) ?? "child"),
      if (item.type != SchoolItemType.allChildType)
        MapEntry("typeable_id", item.id.toString()),
      if (item.type == SchoolItemType.level)
        MapEntry("level_id", item.id.toString()),
      if (item.type == SchoolItemType.classType)
        MapEntry("class_id", item.id.toString()),
      if (item.type == SchoolItemType.childType)
        MapEntry("child_id", item.id.toString()),
    ]);

    // Add questions with proper indexing
    int fieldIndex = 0;
    for (final category in categories) {
      for (final question in category.questions!) {
        final baseKey = 'fields[$fieldIndex]';

    //     formData.fields.addAll([
    //       MapEntry("$baseKey[timeline_category_id]", category.id.toString()),
    //       MapEntry("$baseKey[id]", question.id.toString()),
    //       MapEntry("$baseKey[type]", category.type ?? "question"),
    //       MapEntry("$baseKey[is_image]",
    //           question.type == QuestionType.image ? "1" : "0"),
    //       if (category.statusType != null)
    //         MapEntry("$baseKey[type_status]", category.statusType!),
    // if (question.type != QuestionType.image) {
    // final metadata = question.toJson();
    // metadata.forEach((key, value) {
    // formData.fields.add(MapEntry("$baseKey[metadata][$key]", value.toString()));
    // });
    // }
    // // if (question.type != QuestionType.image)
    // // final metadata = question.toJson() as Map<String, dynamic>;
    // // metadata.forEach((key, value) {
    // // formData.fields.add(MapEntry("$baseKey[metadata][$key]", value.toString()));
    // // });
    //
    //       // if (question.type != QuestionType.image)
    //       //   MapEntry("$baseKey[metadata]", jsonEncode([question.toJson()])),
    //     ]);
        formData.fields.addAll([
          MapEntry("$baseKey[timeline_category_id]", category.id.toString()),
          MapEntry("$baseKey[id]", question.id.toString()),
          MapEntry("$baseKey[type]", category.type ?? "question"),
          MapEntry("$baseKey[is_image]",
              question.type == QuestionType.image ? "1" : "0"),
          if (category.statusType != null)
            MapEntry("$baseKey[type_status]", category.statusType!),
        ]);

        // Process metadata separately
        if (question.type != QuestionType.image) {
          final metadata = question.toJson();
          metadata.forEach((key, value) {
            formData.fields.add(MapEntry("$baseKey[metadata][$key]", value.toString()));
          });
        }
        // Handle value based on question type
        final value = getSelectedItemValue(question);
        if (question.type == QuestionType.image) {
          // For images, add each file separately with array notation
          for (final file in value) {
            formData.files.add(MapEntry("$baseKey[value][]", file));
          }
        } else {
          formData.fields.add(MapEntry("$baseKey[value]", value.toString()));
        }

        fieldIndex++;
      }
    }

    return await networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.post,
        url: sendQuestionsEndpoint,
        body: formData,
      ),
      onSuccess: (json) {},
    );
  }
  @override
  Future<Either<Failure, List<SchoolItem>>> getSchoolItems() async {
    // final data = await rootBundle.loadString('assets/json/diary_items.json');
    return await networkClient.handleRequest<List<SchoolItem>>(
      NetworkRequest(method: HttpMethod.get, url: diaryItemsEndpoint),
      // testJson: data,
      onSuccess: (json) {
        final items = <SchoolItem>[];
        for (final item in json['data']?['school_levels']) {
          items.add(SchoolItem.fromJson(item, SchoolItemType.level));
        }
        for (final item in json['data']?['school_classes']) {
          items.add(SchoolItem.fromJson(item, SchoolItemType.classType));
        }
        for (final item in json['data']?['children']) {
          items.add(SchoolItem.fromJson(item, SchoolItemType.childType));
        }

        return items;
      },
    );
  }

  String? _getTypeableType(SchoolItem item) {
    if (item.type == SchoolItemType.classType) {
      return "class";
    } else if (item.type == SchoolItemType.childType) {
      return "child";
    } else if (item.type == SchoolItemType.allChildType) {
      return null;
    } else if (item.type == SchoolItemType.level) {
      return "level";
    }
    return "child";
  }

  @override
  Future<Either<Failure, List<String>>> uploadAttachments(List<String> filePathes) async {
    final body = {
      for (int i = 0; i < filePathes.length; i++)
        'files[$i]': await MultipartFile.fromFile(
          filePathes[i],
          filename: filePathes[i].split('/').last,
        )
    };
    return await networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.post,
        url: uploadFiles,
        body: FormData.fromMap(body),
      ),
      onSuccess: (json) {
        return List<String>.from(json['data']['files']);
      },
    );
  }

  @override
  Future<Either<Failure, List<ChildMenuModel>>> getMenus({required DateTime? dateTime, required int? childId}) async {
    final formtedDate = dateTime?.toIso8601String().split('T').first;
    final queryParameters = {
      if (formtedDate != null) 'date': formtedDate,
      if (childId != null) 'child_id': childId.toString(),
    };
    return await networkClient.handleRequest<List<ChildMenuModel>>(
      NetworkRequest(
        method: HttpMethod.get,
        url: menusEndpoint,
        queryParameters: queryParameters,
      ),
      onSuccess: (json) {
        final menus = <ChildMenuModel>[];
        for (final activity in json['data']) {
          menus.add(ChildMenuModel.fromJson(activity));
        }
        return menus;
      },
    );
  }
}
