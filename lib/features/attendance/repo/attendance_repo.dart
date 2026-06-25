import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/network/network_models.dart';
import 'package:escola/features/attendance/model/attendance_model.dart';

class AttendanceRepo {
  final NetworkClientRepository networkClient;

  AttendanceRepo({required this.networkClient});

  /// Teacher fetches attendance rows for a given class + date.
  Future<Either<Failure, List<AttendanceModel>>> getAttendance({
    required int classId,
    required String date,
  }) async {
    return networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.get,
        url: 'teacher/attendance',
        queryParameters: {
          'class_id': classId,
          'date': date,
        },
      ),
      onSuccess: (json) {
        final data = <AttendanceModel>[];
        for (final item in (json['data'] as List? ?? const [])) {
          if (item is Map<String, dynamic>) {
            data.add(AttendanceModel.fromJson(item));
          }
        }
        return data;
      },
    );
  }

  /// Mark a single child.
  Future<Either<Failure, AttendanceModel>> markSingle({
    required int classId,
    required int childId,
    required String date,
    required AttendanceStatus status,
    String? notes,
  }) async {
    return networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.post,
        url: 'teacher/attendance',
        body: {
          'class_id': classId,
          'child_id': childId,
          'date': date,
          'status': attendanceStatusToString(status),
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      ),
      onSuccess: (json) => AttendanceModel.fromJson(json['data']),
    );
  }

  /// Bulk mark a whole class. `records` is a list of `{child_id, status}`.
  Future<Either<Failure, List<AttendanceModel>>> markBulk({
    required int classId,
    required String date,
    required List<Map<String, dynamic>> records,
  }) async {
    return networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.post,
        url: 'teacher/attendance/bulk',
        body: {
          'class_id': classId,
          'date': date,
          'records': records,
        },
      ),
      onSuccess: (json) {
        final data = <AttendanceModel>[];
        for (final item in (json['data'] as List? ?? const [])) {
          if (item is Map<String, dynamic>) {
            data.add(AttendanceModel.fromJson(item));
          }
        }
        return data;
      },
    );
  }

  /// Update a single existing attendance row.
  Future<Either<Failure, AttendanceModel>> update({
    required int id,
    AttendanceStatus? status,
    String? notes,
    String? checkedInAt,
    String? checkedOutAt,
  }) async {
    return networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.put,
        url: 'teacher/attendance/$id',
        body: {
          if (status != null) 'status': attendanceStatusToString(status),
          if (notes != null) 'notes': notes,
          if (checkedInAt != null) 'checked_in_at': checkedInAt,
          if (checkedOutAt != null) 'checked_out_at': checkedOutAt,
        },
      ),
      onSuccess: (json) => AttendanceModel.fromJson(json['data']),
    );
  }

  /// Admin dashboard: today's counts + full list.
  Future<Either<Failure, AttendanceTodayModel>> getToday() async {
    return networkClient.handleRequest(
      const NetworkRequest(
        method: HttpMethod.get,
        url: 'admin/attendance/today',
      ),
      onSuccess: (json) => AttendanceTodayModel.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}
