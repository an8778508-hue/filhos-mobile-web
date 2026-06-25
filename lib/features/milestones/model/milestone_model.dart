import 'package:equatable/equatable.dart';
import 'package:escola/core/utils/valid_data.dart';

/// A developmental milestone, optionally annotated with a child's progress.
///
/// Mirrors the backend resources:
/// - catalog item: `{ id, domain, age_band_min, age_band_max, description_ar }`
/// - per-child view: the above plus `{ reached, overdue, observed_at }`.
class MilestoneModel extends Equatable {
  final int id;
  final String domain; // social | language | cognitive | motor
  final int ageBandMin; // months
  final int ageBandMax; // months
  final String descriptionAr;
  final bool reached;
  final bool overdue;
  final String? observedAt;

  const MilestoneModel({
    required this.id,
    required this.domain,
    required this.ageBandMin,
    required this.ageBandMax,
    required this.descriptionAr,
    this.reached = false,
    this.overdue = false,
    this.observedAt,
  });

  factory MilestoneModel.fromJson(Map<String, dynamic> json) => MilestoneModel(
        id: validateInt(json['id']),
        domain: validateString(json['domain']),
        ageBandMin: validateInt(json['age_band_min']),
        ageBandMax: validateInt(json['age_band_max']),
        descriptionAr: validateString(json['description_ar']),
        reached: validateBool(json['reached']),
        overdue: validateBool(json['overdue']),
        observedAt: validString(json['observed_at']) ? json['observed_at'] as String : null,
      );

  MilestoneModel copyWith({
    bool? reached,
    bool? overdue,
    String? observedAt,
  }) =>
      MilestoneModel(
        id: id,
        domain: domain,
        ageBandMin: ageBandMin,
        ageBandMax: ageBandMax,
        descriptionAr: descriptionAr,
        reached: reached ?? this.reached,
        overdue: overdue ?? this.overdue,
        observedAt: observedAt ?? this.observedAt,
      );

  @override
  List<Object?> get props =>
      [id, domain, ageBandMin, ageBandMax, descriptionAr, reached, overdue, observedAt];
}
