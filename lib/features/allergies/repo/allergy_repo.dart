import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/network/network_models.dart';
import 'package:escola/features/allergies/model/allergy_model.dart';

class AllergyRepo {
  final NetworkClientRepository networkClient;

  AllergyRepo({required this.networkClient});

  /// Fetch a child's allergy records.
  ///
  /// The endpoint differs per caller flavor / role:
  /// - `parent/children/{childId}/allergies` (parent, own child)
  /// - `teacher/children/{childId}/allergies` (any teacher)
  /// - `admin/children/{childId}/allergies` (nursery admin)
  Future<Either<Failure, List<AllergyModel>>> getForChild(
    int childId, {
    String prefix = 'parent',
  }) async {
    return networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.get,
        url: '$prefix/children/$childId/allergies',
      ),
      onSuccess: (json) {
        final data = <AllergyModel>[];
        for (final item in (json['data'] as List? ?? const [])) {
          if (item is Map<String, dynamic>) {
            data.add(AllergyModel.fromJson(item));
          }
        }
        return data;
      },
    );
  }

  /// Admin: create an allergy record for a child.
  Future<Either<Failure, AllergyModel>> create({
    required int childId,
    required String allergen,
    required String severity,
    required String reactionDescription,
    required String actionToTake,
  }) async {
    return networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.post,
        url: 'admin/children/$childId/allergies',
        body: {
          'allergen': allergen,
          'severity': severity,
          'reaction_description': reactionDescription,
          'action_to_take': actionToTake,
        },
      ),
      onSuccess: (json) => AllergyModel.fromJson(json['data']),
    );
  }

  /// Admin: update an existing allergy record.
  Future<Either<Failure, AllergyModel>> update({
    required int id,
    required String allergen,
    required String severity,
    required String reactionDescription,
    required String actionToTake,
  }) async {
    return networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.put,
        url: 'admin/allergies/$id',
        body: {
          'allergen': allergen,
          'severity': severity,
          'reaction_description': reactionDescription,
          'action_to_take': actionToTake,
        },
      ),
      onSuccess: (json) => AllergyModel.fromJson(json['data']),
    );
  }

  /// Admin: delete an allergy record.
  Future<Either<Failure, bool>> delete(int id) async {
    return networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.delete,
        url: 'admin/allergies/$id',
      ),
      onSuccess: (_) => true,
    );
  }
}
