import 'package:escola/features/subscription/model/subscription_model.dart';
import 'package:flutter/material.dart';

/// A compact banner shown on the admin dashboard summarising the nursery's
/// subscription. During a free trial it renders in AMBER with the number of
/// days remaining so admins are reminded to upgrade.
class SubscriptionBanner extends StatelessWidget {
  static const Key amberTrialKey = Key('subscription_trial_banner_amber');
  static const Key bannerKey = Key('subscription_banner');

  final SubscriptionModel subscription;

  const SubscriptionBanner({super.key, required this.subscription});

  static const Color amber = Color(0xFFFFC107);

  @override
  Widget build(BuildContext context) {
    final bool isTrial = subscription.isTrial;
    final int days = subscription.daysRemaining ?? 0;

    final Color background = isTrial ? amber.withOpacity(0.15) : Colors.green.withOpacity(0.12);
    final Color border = isTrial ? amber : Colors.green;

    final String message = isTrial
        ? 'Free trial - $days day${days == 1 ? '' : 's'} remaining'
        : 'Subscription active (${subscription.plan})';

    return Container(
      key: isTrial ? amberTrialKey : bannerKey,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            isTrial ? Icons.timer_outlined : Icons.verified_outlined,
            color: border,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isTrial ? const Color(0xFF8A6D00) : Colors.green.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isTrial)
            Text(
              '$days',
              style: const TextStyle(
                color: Color(0xFF8A6D00),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
        ],
      ),
    );
  }
}
