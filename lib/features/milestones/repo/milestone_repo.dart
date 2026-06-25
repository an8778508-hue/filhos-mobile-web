import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/network/network_models.dart';
import 'package:escola/features/milestones/model/milestone_model.dart';

class MilestoneRepo {
  final NetworkClientRepository networkClient;

  MilestoneRepo({required this.networkClient});

  List<MilestoneModel> _parseList(dynamic data) {
    final result = <MilestoneModel>[];
    for (final item in (data as List? ?? const [])) {
      if (item is Map<String, dynamic>) {
        result.add(MilestoneModel.fromJson(item));
      }
    }
    return result;
  }

  /// Full milestone catalog (any authenticated user).
  Future<Either<Failure, List<MilestoneModel>>> getCatalog() async {
    return networkClient.handleRequest(
      const NetworkRequest(
        method: HttpMethod.get,
        url: 'milestones',
      ),
      onSuccess: (json) => _parseList(json['data']),
    );
  }

  /// Per-child milestone view (reached + overdue flags).
  ///
  /// Hits `parent/children/{childId}/milestones` for the parents flavor and
  /// `admin/children/{childId}/milestones` for the teachers/admin flavor.
  Future<Either<Failure, List<MilestoneModel>>> getChildMilestones(
    int childId, {
    bool asTeacher = false,
  }) async {
    final prefix = asTeacher ? 'admin' : 'parent';
    return networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.get,
        url: '$prefix/children/$childId/milestones',
      ),
      onSuccess: (json) => _parseList(json['data']),
    );
  }

  /// Teacher marks a milestone reached for a child in their class.
  Future<Either<Failure, bool>> mark({
    required int childId,
    required int milestoneId,
    String? notes,
    String? observedAt,
  }) async {
    return networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.post,
        url: 'teacher/children/$childId/milestones',
        body: {
          'milestone_id': milestoneId,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          if (observedAt != null && observedAt.isNotEmpty) 'observed_at': observedAt,
        },
      ),
      onSuccess: (_) => true,
    );
  }
}
