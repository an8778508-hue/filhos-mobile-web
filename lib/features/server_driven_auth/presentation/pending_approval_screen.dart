import 'package:escola/features/your_account_under_review/presentation/your_account_under_review_screen.dart';
import 'package:flutter/material.dart';

/// Scenarios 2 and 4 destination. v1 delegates to the existing
/// `YourAccountUnderReviewScreen` so the visual identity stays consistent
/// across legacy and server-driven paths. Kept as a distinct class so future
/// product copy can diverge without ripple effects.
class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const YourAccountUnderReviewScreen();
}
