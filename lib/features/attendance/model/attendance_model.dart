import 'package:equatable/equatable.dart';
import 'package:escola/core/utils/valid_data.dart';

/// Allowed attendance statuses, matching the backend `in:present,late,absent`.
enum AttendanceStatus { present, late, absent }

AttendanceStatus attendanceStatusFromString(String? value) {
  switch (value) {
    case 'late':
      return AttendanceStatus.late;
    case 'absent':
      return AttendanceStatus.absent;
    case 'present':
    default:
      return AttendanceStatus.present;
  }
}

String attendanceStatusToString(AttendanceStatus status) {
  switch (status) {
    case AttendanceStatus.late:
      return 'late';
    case AttendanceStatus.absent:
      return 'absent';
    case AttendanceStatus.present:
      return 'present';
  }
}

/// A single attendance row.
///
/// Mirrors the backend `AttendanceResource`:
/// `{ id, date, status, checked_in_at, checked_out_at, notes, child: {id, name}, class_id, created_at }`.
class AttendanceModel extends Equatable {
  final int id;
  final String? date;
  final AttendanceStatus status;
  final String? checkedInAt;
  final String? checkedOutAt;
  final String? notes;
  final int childId;
  final String childName;
  final int classId;
  final String? createdAt;

  const AttendanceModel({
    required this.id,
    required this.childId,
    required this.childName,
    required this.classId,
    this.date,
    this.status = AttendanceStatus.present,
    this.checkedInAt,
    this.checkedOutAt,
    this.notes,
    this.createdAt,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    final child = validMap<String, dynamic>(json['child']) ? json['child'] as Map<String, dynamic> : null;

    return AttendanceModel(
      id: validateInt(json['id']),
      date: validString(json['date']) ? json['date'] as String : null,
      status: attendanceStatusFromString(validString(json['status']) ? json['status'] as String : null),
      checkedInAt: validString(json['checked_in_at']) ? json['checked_in_at'] as String : null,
      checkedOutAt: validString(json['checked_out_at']) ? json['checked_out_at'] as String : null,
      notes: validString(json['notes']) ? json['notes'] as String : null,
      childId: child != null ? validateInt(child['id']) : 0,
      childName: child != null ? validateString(child['name']) : '',
      classId: validateInt(json['class_id']),
      createdAt: validString(json['created_at']) ? json['created_at'] as String : null,
    );
  }

  AttendanceModel copyWith({AttendanceStatus? status, String? notes}) => AttendanceModel(
        id: id,
        childId: childId,
        childName: childName,
        classId: classId,
        date: date,
        status: status ?? this.status,
        checkedInAt: checkedInAt,
        checkedOutAt: checkedOutAt,
        notes: notes ?? this.notes,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props =>
      [id, date, status, checkedInAt, checkedOutAt, notes, childId, childName, classId, createdAt];
}

/// Today's aggregate counts for the admin dashboard.
class AttendanceTodayModel extends Equatable {
  final String? date;
  final int present;
  final int late;
  final int absent;
  final int total;
  final List<AttendanceModel> records;

  const AttendanceTodayModel({
    this.date,
    this.present = 0,
    this.late = 0,
    this.absent = 0,
    this.total = 0,
    this.records = const [],
  });

  factory AttendanceTodayModel.fromJson(Map<String, dynamic> json) {
    final counts = validMap<String, dynamic>(json['counts']) ? json['counts'] as Map<String, dynamic> : const {};

    return AttendanceTodayModel(
      date: validString(json['date']) ? json['date'] as String : null,
      present: validateInt(counts['present']),
      late: validateInt(counts['late']),
      absent: validateInt(counts['absent']),
      total: validateInt(counts['total']),
      records: validateDataList(json['records'], AttendanceModel.fromJson),
    );
  }

  @override
  List<Object?> get props => [date, present, late, absent, total, records];
}
