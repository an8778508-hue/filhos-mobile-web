/// Lightweight, framework-free role-capability helper mirroring the backend's
/// 4-tier nursery staff taxonomy (Botble\Filhos\Supports\NurseryRoles).
///
/// Role string values (as stored server-side in `fi_teachers.staff_role`):
///   - 'owner'             (nursery_owner)     => ALL capabilities
///   - 'admin'             (nursery_admin)     => all EXCEPT billing
///   - 'lead_teacher'                           => attendance, reports, incidents, gallery, messaging
///   - 'assistant_teacher'                      => reports, gallery, messaging
///
/// BACKWARD-COMPAT: a null/empty role is treated as FULL ACCESS (every
/// capability) so existing accounts without a staff_role keep working.
library;

enum NurseryCapability {
  attendance,
  reports,
  incidents,
  gallery,
  messaging,
  billing,
}

class NurseryRole {
  const NurseryRole(this.role);

  /// The raw staff_role string from the server (may be null/empty).
  final String? role;

  static const String owner = 'owner';
  static const String admin = 'admin';
  static const String leadTeacher = 'lead_teacher';
  static const String assistantTeacher = 'assistant_teacher';

  static const Map<String, Set<NurseryCapability>> _map = {
    owner: {
      NurseryCapability.attendance,
      NurseryCapability.reports,
      NurseryCapability.incidents,
      NurseryCapability.gallery,
      NurseryCapability.messaging,
      NurseryCapability.billing,
    },
    admin: {
      NurseryCapability.attendance,
      NurseryCapability.reports,
      NurseryCapability.incidents,
      NurseryCapability.gallery,
      NurseryCapability.messaging,
      // NO billing.
    },
    leadTeacher: {
      NurseryCapability.attendance,
      NurseryCapability.reports,
      NurseryCapability.incidents,
      NurseryCapability.gallery,
      NurseryCapability.messaging,
    },
    assistantTeacher: {
      NurseryCapability.reports,
      NurseryCapability.gallery,
      NurseryCapability.messaging,
      // NO incidents, NO attendance, NO billing.
    },
  };

  bool get _isFullAccess => role == null || role!.isEmpty;

  bool can(NurseryCapability capability) {
    if (_isFullAccess) return true;
    return _map[role]?.contains(capability) ?? false;
  }

  bool get canTakeAttendance => can(NurseryCapability.attendance);
  bool get canWriteReports => can(NurseryCapability.reports);
  bool get canSeeIncidents => can(NurseryCapability.incidents);
  bool get canUseGallery => can(NurseryCapability.gallery);
  bool get canSendMessages => can(NurseryCapability.messaging);
  bool get canManageBilling => can(NurseryCapability.billing);
}
