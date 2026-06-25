import 'package:equatable/equatable.dart';
import 'package:escola/core/utils/valid_data.dart';

/// A single structured allergy record for a child.
///
/// Mirrors the backend `AllergyResource`:
/// `{ id, allergen, severity, reaction_description, action_to_take,
///    child_id, created_at, updated_at }`.
class AllergyModel extends Equatable {
  final int id;
  final String allergen;
  final String severity; // mild | moderate | severe
  final String? reactionDescription;
  final String? actionToTake;
  final int? childId;
  final String? createdAt;
  final String? updatedAt;

  const AllergyModel({
    required this.id,
    required this.allergen,
    this.severity = 'mild',
    this.reactionDescription,
    this.actionToTake,
    this.childId,
    this.createdAt,
    this.updatedAt,
  });

  factory AllergyModel.fromJson(Map<String, dynamic> json) {
    return AllergyModel(
      id: validateInt(json['id']),
      allergen: validateString(json['allergen']),
      severity: validateString(json['severity'], 'mild'),
      reactionDescription:
          validString(json['reaction_description']) ? json['reaction_description'] as String : null,
      actionToTake: validString(json['action_to_take']) ? json['action_to_take'] as String : null,
      childId: validInt(json['child_id']) ? json['child_id'] as int : null,
      createdAt: validString(json['created_at']) ? json['created_at'] as String : null,
      updatedAt: validString(json['updated_at']) ? json['updated_at'] as String : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'allergen': allergen,
        'severity': severity,
        'reaction_description': reactionDescription,
        'action_to_take': actionToTake,
      };

  @override
  List<Object?> get props =>
      [id, allergen, severity, reactionDescription, actionToTake, childId, createdAt, updatedAt];
}
