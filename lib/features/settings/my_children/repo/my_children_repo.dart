import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/network/network_models.dart';
import 'package:escola/features/diary/models/child_model.dart';

class MyChildrenRepo {
  final String childrenEndpoint = '/parent/children';

  final NetworkClientRepository networkClient;
  MyChildrenRepo({required this.networkClient});

  Future<Either<Failure, List<ChildModel>>> getChildren(int page) async {
    return await networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.get,
        url: childrenEndpoint,
      ),
      onSuccess: (json) {
        final children =
            (json['data']['childs'] as List).map((e) => ChildModel.fromJson(e)).toList();
        return children;
      },
    );
  }
}
