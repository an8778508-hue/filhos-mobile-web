import 'package:escola/core/user/nursery_role.dart';
import 'package:flutter/material.dart';

/// A "Log incident" action button that is role-aware: it is only rendered for
/// staff whose nursery role grants the `incidents` capability.
///
/// - lead_teacher / admin / owner (and null-role / full-access) => button shown.
/// - assistant_teacher => button hidden (renders nothing).
class IncidentActionButton extends StatelessWidget {
  const IncidentActionButton({
    super.key,
    required this.role,
    required this.onPressed,
    this.label = 'Log incident',
  });

  /// The current staff member's role helper.
  final NurseryRole role;
  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (!role.canSeeIncidents) {
      return const SizedBox.shrink();
    }

    return ElevatedButton.icon(
      key: const ValueKey('incident_action_button'),
      onPressed: onPressed,
      icon: const Icon(Icons.report_problem_outlined),
      label: Text(label),
    );
  }
}
