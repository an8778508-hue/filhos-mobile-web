import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/network/network_models.dart';
import 'package:escola/features/urgent_messages/model/urgent_message_model.dart';

class UrgentMessageRepo {
  final NetworkClientRepository networkClient;

  UrgentMessageRepo({required this.networkClient});

  Future<Either<Failure, List<UrgentMessageModel>>> getMessages() async {
    return await networkClient.handleRequest(
      const NetworkRequest(
        method: HttpMethod.get,
        url: 'parent/urgent-messages',
      ),
      onSuccess: (json) {
        final data = <UrgentMessageModel>[];
        for (final item in (json['data'] as List? ?? [])) {
          if (item is Map<String, dynamic>) {
            data.add(UrgentMessageModel.fromJson(item));
          }
        }
        return data;
      },
    );
  }

  Future<Either<Failure, UrgentMessageModel>> markRead(int id) async {
    return await networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.put,
        url: 'parent/urgent-messages/$id/read',
      ),
      onSuccess: (json) => UrgentMessageModel.fromJson(json['data']),
    );
  }

  Future<Either<Failure, UrgentMessageModel>> send({
    required int parentId,
    int? childId,
    required String title,
    required String description,
  }) async {
    return await networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.post,
        url: 'teacher/urgent-messages',
        body: {
          'parent_id': parentId,
          'child_id': childId,
          'title': title,
          'description': description,
        },
      ),
      onSuccess: (json) => UrgentMessageModel.fromJson(json['data']),
    );
  }
}
