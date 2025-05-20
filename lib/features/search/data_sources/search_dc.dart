import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/network/network_models.dart';
import 'package:escola/features/diary/models/school_item.dart';
import 'package:escola/features/search/models/global_search.dart';
import 'package:flutter/cupertino.dart';

abstract class SearchRepo {
  final String childSearchEndpoint = "/teacher/timeline/";
  final String globalSearchEndpoint = "/teacher/timeline/";
  final String parentSearchEndpoint = "/parent/timeline";
  final String professorSearchEndpoint = "teacher/teacher-search";

  Future<Either<Failure, List<SchoolItem>>> childSearch(String query);

  Future<Either<Failure, GlobalSearchResult>> globalSearchForProfessor(String query, bool isTeacher);

  Future<Either<Failure, List<SchoolItem>>> professorSearch(String query);
}

class SearchImpl extends SearchRepo {
  final NetworkClientRepository networkClient;

  SearchImpl({required this.networkClient});

  @override
  Future<Either<Failure, List<SchoolItem>>> childSearch(String query) async {
    final queryParameters = {'q': query};

    return await networkClient.handleRequest<List<SchoolItem>>(
      NetworkRequest(method: HttpMethod.get, url: childSearchEndpoint, queryParameters: queryParameters),
      onSuccess: (json) {
        final items = <SchoolItem>[];
        for (final item in json['data']) {
          items.add(SchoolItem.fromJson(item, SchoolItemType.childType));
        }

        return items;
      },
    );
  }

  @override
  // Future<Either<Failure, GlobalSearchResult>> globalSearchForProfessor(String query) async {
  //   final queryParameters = {'q': query};
  //
  //   return await networkClient.handleRequest<GlobalSearchResult>(
  //     NetworkRequest(method: HttpMethod.get, url: globalSearchEndpoint, queryParameters: queryParameters),
  //     onSuccess: (json) {
  //       final List<SchoolItem> teachers = [];
  //       final List<SchoolItem> parents = [];
  //       final List<SchoolItem> levels = [];
  //       final List<SchoolItem> children = [];
  //
  //       for (final item in json['data']?['teachers']??[]) {
  //         teachers.add(SchoolItem.fromJson(item, SchoolItemType.teacherType));
  //       }
  //       for (final item in json['data']?['parents']??[]) {
  //         parents.add(SchoolItem.fromJson(item, SchoolItemType.parentType));
  //       }
  //       for (final item in json['data']?['children']??[]) {
  //         children.add(SchoolItem.fromJson(item, SchoolItemType.childType));
  //       }
  //       for (final item in json['data']?['levels']??[]) {
  //         levels.add(SchoolItem.fromJson(item, SchoolItemType.level));
  //       }
  //
  //       return GlobalSearchResult(
  //         teachers: teachers,
  //         parents: parents,
  //         children: children,
  //         levels: levels,
  //       );
  //     },
  //   );
  // }
  Future<Either<Failure, GlobalSearchResult>> globalSearchForProfessor(String query, bool isTeacher) async {
    final queryParameters = {'q': query};

    return await networkClient.handleRequest<GlobalSearchResult>(
      NetworkRequest(method: HttpMethod.get, url:isTeacher? globalSearchEndpoint: parentSearchEndpoint, queryParameters: queryParameters),
      onSuccess: (json) {
        final List<SchoolItem> teachers = [];
        final List<SchoolItem> parents = [];
        final List<SchoolItem> levels = [];
        final List<SchoolItem> children = [];

        // The API is returning data as a direct array, not categorized objects
        if (json['data'] is List) {
          // Assuming these are children based on the response structure
          for (final item in json['data']) {

            if(isTeacher==false){
              if (item['type'] == 'Parent') {
                parents.add(SchoolItem.fromJson(item, SchoolItemType.parentType));
              } else if (item['type'] == 'professor') {
                debugPrint('dddddddddddddddddddddddddddddddddd');
                teachers.add(SchoolItem.fromJson(item, SchoolItemType.teacherType));
              } else if (item['type'] == 'Level') {
                levels.add(SchoolItem.fromJson(item, SchoolItemType.level));
              }
            }else{
              children.add(SchoolItem.fromJson(item, SchoolItemType.childType));
            }

          }
        } else if (json['data'] is Map) {
          // Handle the case where data might be an object with categorized arrays
          for (final item in json['data']?['teachers'] ?? []) {
            teachers.add(SchoolItem.fromJson(item, SchoolItemType.teacherType));
          }
          for (final item in json['data']?['parents'] ?? []) {
            parents.add(SchoolItem.fromJson(item, SchoolItemType.parentType));
          }
          for (final item in json['data']?['children'] ?? []) {

            children.add(SchoolItem.fromJson(item, SchoolItemType.childType));
          }
          for (final item in json['data']?['levels'] ?? []) {
            levels.add(SchoolItem.fromJson(item, SchoolItemType.level));
          }
        }

        return GlobalSearchResult(
          teachers: teachers,
          parents: parents,
          children: children,
          levels: levels,
        );
      },
    );
  }
  @override
  Future<Either<Failure, List<SchoolItem>>> professorSearch(String query) async {
    final queryParameters = {'q': query};

    return await networkClient.handleRequest<List<SchoolItem>>(
      NetworkRequest(method: HttpMethod.get, url: professorSearchEndpoint, queryParameters: queryParameters),
      onSuccess: (json) {
        final items = <SchoolItem>[];
        for (final item in json['data']) {
          items.add(SchoolItem.fromJson(item, SchoolItemType.teacherType));
        }

        return items;
      },
    );
  }
}
