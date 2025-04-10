import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/network/network_models.dart';
import 'package:escola/features/diary/models/school_item.dart';

abstract class AllChildrenRepo {
  final String allChildrentEndpoint = "teacher/questions/data";

  Future<Either<Failure, List<SchoolItem>>> getAllChildren();
}

class AllChildrenImpl extends AllChildrenRepo {
  final NetworkClientRepository networkClient;

  AllChildrenImpl({required this.networkClient});
  @override
  Future<Either<Failure, List<SchoolItem>>> getAllChildren() async {
    return await networkClient.handleRequest<List<SchoolItem>>(
      NetworkRequest(
        method: HttpMethod.get,
        url: allChildrentEndpoint,
      ),
      onSuccess: (json) {
        final items = <SchoolItem>[];
        for (final item in json['data']['children']) {
          items.add(SchoolItem.fromJson(item, SchoolItemType.childType));
        }

        return items;
      },
    );
  }
}
