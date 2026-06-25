import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/network/network_models.dart';
import 'package:escola/features/incidents/model/incident_model.dart';

class IncidentRepo {
  final NetworkClientRepository networkClient;

  IncidentRepo({required this.networkClient});

  List<IncidentModel> _parseList(dynamic json) {
    final data = <IncidentModel>[];
    for (final item in (json['data'] as List? ?? [])) {
      if (item is Map<String, dynamic>) {
        data.add(IncidentModel.fromJson(item));
      }
    }
    return data;
  }

  /// Teacher: log a new incident report.
  Future<Either<Failure, IncidentModel>> logIncident({
    required int childId,
    required String incidentType,
    required String severity,
    required String description,
    required String actionTaken,
    String? occurredAt,
  }) async {
    return await networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.post,
        url: 'teacher/incidents',
        body: {
          'child_id': childId,
          'incident_type': incidentType,
          'severity': severity,
          'description': description,
          'action_taken': actionTaken,
          'occurred_at': occurredAt,
        },
      ),
      onSuccess: (json) => IncidentModel.fromJson(json['data']),
    );
  }

  /// Teacher: only the authenticated teacher's own reports.
  Future<Either<Failure, List<IncidentModel>>> getTeacherIncidents() async {
    return await networkClient.handleRequest(
      const NetworkRequest(
        method: HttpMethod.get,
        url: 'teacher/incidents',
      ),
      onSuccess: _parseList,
    );
  }

  /// Admin: all incidents with optional filters.
  Future<Either<Failure, List<IncidentModel>>> getAdminIncidents({
    int? childId,
    String? incidentType,
    String? severity,
    String? from,
    String? to,
  }) async {
    final query = <String, dynamic>{};
    if (childId != null) query['child_id'] = childId;
    if (incidentType != null && incidentType.isNotEmpty) query['incident_type'] = incidentType;
    if (severity != null && severity.isNotEmpty) query['severity'] = severity;
    if (from != null && from.isNotEmpty) query['from'] = from;
    if (to != null && to.isNotEmpty) query['to'] = to;

    return await networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.get,
        url: 'admin/incidents',
        queryParameters: query.isEmpty ? null : query,
      ),
      onSuccess: _parseList,
    );
  }

  /// Parent: incidents for one of their own children.
  Future<Either<Failure, List<IncidentModel>>> getChildIncidents(int childId) async {
    return await networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.get,
        url: 'parent/children/$childId/incidents',
      ),
      onSuccess: _parseList,
    );
  }
}
