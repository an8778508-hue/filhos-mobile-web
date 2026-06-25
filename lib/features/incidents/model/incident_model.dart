import 'package:equatable/equatable.dart';
import 'package:escola/core/utils/valid_data.dart';

/// A single incident / accident report for a child.
///
/// Mirrors the backend `IncidentResource`:
/// `{ id, incident_type, severity, description, action_taken, parent_notified,
///    occurred_at, child:{id,name}, reported_by:{id,name}, created_at }`.
class IncidentModel extends Equatable {
  final int id;
  final String incidentType;
  final String severity;
  final String description;
  final String actionTaken;
  final bool parentNotified;
  final String? occurredAt;
  final int? childId;
  final String? childName;
  final String? reportedByName;
  final String? createdAt;

  const IncidentModel({
    required this.id,
    required this.incidentType,
    required this.severity,
    required this.description,
    required this.actionTaken,
    this.parentNotified = false,
    this.occurredAt,
    this.childId,
    this.childName,
    this.reportedByName,
    this.createdAt,
  });

  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    final child = validateDataModel(json['child'], (e) => e);
    final reportedBy = validateDataModel(json['reported_by'], (e) => e);
    return IncidentModel(
      id: validateInt(json['id']),
      incidentType: validateString(json['incident_type']),
      severity: validateString(json['severity']),
      description: validateString(json['description']),
      actionTaken: validateString(json['action_taken']),
      parentNotified: validateBool(json['parent_notified']),
      occurredAt: validString(json['occurred_at']) ? json['occurred_at'] as String : null,
      childId: child != null ? validateInt(child['id']) : null,
      childName: child != null && validString(child['name']) ? child['name'] as String : null,
      reportedByName:
          reportedBy != null && validString(reportedBy['name']) ? reportedBy['name'] as String : null,
      createdAt: validString(json['created_at']) ? json['created_at'] as String : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        incidentType,
        severity,
        description,
        actionTaken,
        parentNotified,
        occurredAt,
        childId,
        childName,
        reportedByName,
        createdAt,
      ];
}
