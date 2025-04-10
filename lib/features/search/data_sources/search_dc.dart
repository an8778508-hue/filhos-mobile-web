import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/network/network_models.dart';
import 'package:escola/features/diary/models/school_item.dart';
import 'package:escola/features/search/models/global_search.dart';

abstract class SearchRepo {
  final String childSearchEndpoint = "/teacher/timeline/";
  final String globalSearchEndpoint = "/teacher/timeline/";
  final String professorSearchEndpoint = "/teacher-search";

  Future<Either<Failure, List<SchoolItem>>> childSearch(String query);

  Future<Either<Failure, GlobalSearchResult>> globalSearchForProfessor(String query);

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
  Future<Either<Failure, GlobalSearchResult>> globalSearchForProfessor(String query) async {
    final queryParameters = {'q': query};

    return await networkClient.handleRequest<GlobalSearchResult>(
      NetworkRequest(method: HttpMethod.get, url: globalSearchEndpoint, queryParameters: queryParameters),
      onSuccess: (json) {
        final List<SchoolItem> teachers = [];
        final List<SchoolItem> parents = [];
        final List<SchoolItem> levels = [];
        final List<SchoolItem> children = [];

        for (final item in json['data']?['teachers']??[]) {
          teachers.add(SchoolItem.fromJson(item, SchoolItemType.teacherType));
        }
        for (final item in json['data']?['parents']??[]) {
          parents.add(SchoolItem.fromJson(item, SchoolItemType.parentType));
        }
        for (final item in json['data']?['children']??[]) {
          children.add(SchoolItem.fromJson(item, SchoolItemType.childType));
        }
        for (final item in json['data']?['levels']??[]) {
          levels.add(SchoolItem.fromJson(item, SchoolItemType.level));
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
        for (final item in json['data']['teachers']) {
          items.add(SchoolItem.fromJson(item, SchoolItemType.teacherType));
        }

        return items;
      },
    );
  }
}
