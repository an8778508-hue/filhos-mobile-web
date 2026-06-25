import 'package:equatable/equatable.dart';
import 'package:escola/core/utils/valid_data.dart';

/// A single immunisation (vaccination) record for a child.
///
/// Mirrors the backend `ImmunisationResource`:
/// `{ id, vaccine_name, date_given, next_due_date, notes, child_id,
///    is_due_soon, created_at }`.
class ImmunisationModel extends Equatable {
  final int id;
  final String vaccineName;
  final String? dateGiven;
  final String? nextDueDate;
  final String? notes;
  final int? childId;
  final bool isDueSoon;
  final String? createdAt;

  const ImmunisationModel({
    required this.id,
    required this.vaccineName,
    this.dateGiven,
    this.nextDueDate,
    this.notes,
    this.childId,
    this.isDueSoon = false,
    this.createdAt,
  });

  factory ImmunisationModel.fromJson(Map<String, dynamic> json) {
    return ImmunisationModel(
      id: validateInt(json['id']),
      vaccineName: validateString(json['vaccine_name']),
      dateGiven: validString(json['date_given']) ? json['date_given'] as String : null,
      nextDueDate: validString(json['next_due_date']) ? json['next_due_date'] as String : null,
      notes: validString(json['notes']) ? json['notes'] as String : null,
      childId: validInt(json['child_id']) ? json['child_id'] as int : null,
      isDueSoon: validateBool(json['is_due_soon']),
      createdAt: validString(json['created_at']) ? json['created_at'] as String : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'vaccine_name': vaccineName,
        'date_given': dateGiven,
        'next_due_date': nextDueDate,
        'notes': notes,
      };

  @override
  List<Object?> get props =>
      [id, vaccineName, dateGiven, nextDueDate, notes, childId, isDueSoon, createdAt];
}
