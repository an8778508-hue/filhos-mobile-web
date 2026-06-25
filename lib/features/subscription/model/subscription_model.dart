import 'package:equatable/equatable.dart';
import 'package:escola/core/utils/valid_data.dart';

/// A nursery's subscription / free-trial state.
///
/// Mirrors the backend `NurserySubscriptionResource`:
/// `{ id, plan, status, trial_ends_at, current_period_end, child_count,
///    price_per_child, total_amount, days_remaining, is_expired }`.
class SubscriptionModel extends Equatable {
  final int id;
  final String plan; // trial | monthly | annual
  final String status; // trial | active | expired | cancelled
  final String? trialEndsAt;
  final int? daysRemaining;
  final bool isExpired;
  final int childCount;
  final double pricePerChild;
  final double totalAmount;

  const SubscriptionModel({
    this.id = 0,
    this.plan = 'trial',
    this.status = 'trial',
    this.trialEndsAt,
    this.daysRemaining,
    this.isExpired = false,
    this.childCount = 0,
    this.pricePerChild = 0,
    this.totalAmount = 0,
  });

  bool get isTrial => status == 'trial';

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) => SubscriptionModel(
        id: validateInt(json['id']),
        plan: validateString(json['plan'], 'trial'),
        status: validateString(json['status'], 'trial'),
        trialEndsAt: validString(json['trial_ends_at']) ? json['trial_ends_at'] as String : null,
        daysRemaining: validInt(json['days_remaining']) || json['days_remaining'] == 0
            ? validateInt(json['days_remaining'])
            : null,
        isExpired: validateBool(json['is_expired']),
        childCount: validateInt(json['child_count']),
        pricePerChild: convertToDouble(json['price_per_child']),
        totalAmount: convertToDouble(json['total_amount']),
      );

  @override
  List<Object?> get props => [
        id,
        plan,
        status,
        trialEndsAt,
        daysRemaining,
        isExpired,
        childCount,
        pricePerChild,
        totalAmount,
      ];
}
