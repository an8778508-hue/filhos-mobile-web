import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/network/network_models.dart';
import 'package:escola/features/immunisations/model/immunisation_model.dart';

class ImmunisationRepo {
  final NetworkClientRepository networkClient;

  ImmunisationRepo({required this.networkClient});

  List<ImmunisationModel> _parseList(dynamic data) {
    final result = <ImmunisationModel>[];
    for (final item in (data as List? ?? const [])) {
      if (item is Map<String, dynamic>) {
        result.add(ImmunisationModel.fromJson(item));
      }
    }
    return result;
  }

  /// Fetch a child's immunisation records.
  ///
  /// The endpoint differs per caller flavor / role:
  /// - `parent/children/{childId}/immunisations` (parent, own child)
  /// - `teacher/children/{childId}/immunisations` (any teacher)
  /// - `admin/children/{childId}/immunisations` (nursery admin)
  Future<Either<Failure, List<ImmunisationModel>>> getForChild(
    int childId, {
    String prefix = 'parent',
  }) async {
    return networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.get,
        url: '$prefix/children/$childId/immunisations',
      ),
      onSuccess: (json) => _parseList(json['data']),
    );
  }

  /// Admin: immunisations due within the next 30 days.
  Future<Either<Failure, List<ImmunisationModel>>> getUpcoming() async {
    return networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.get,
        url: 'admin/immunisations/upcoming',
      ),
      onSuccess: (json) => _parseList(json['data']),
    );
  }

  /// Admin: create an immunisation record for a child.
  Future<Either<Failure, ImmunisationModel>> create({
    required int childId,
    required String vaccineName,
    required String dateGiven,
    String? nextDueDate,
    String? notes,
  }) async {
    return networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.post,
        url: 'admin/children/$childId/immunisations',
        body: {
          'vaccine_name': vaccineName,
          'date_given': dateGiven,
          'next_due_date': nextDueDate,
          'notes': notes,
        },
      ),
      onSuccess: (json) => ImmunisationModel.fromJson(json['data']),
    );
  }

  /// Admin: update an existing immunisation record.
  Future<Either<Failure, ImmunisationModel>> update({
    required int id,
    required String vaccineName,
    required String dateGiven,
    String? nextDueDate,
    String? notes,
  }) async {
    return networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.put,
        url: 'admin/immunisations/$id',
        body: {
          'vaccine_name': vaccineName,
          'date_given': dateGiven,
          'next_due_date': nextDueDate,
          'notes': notes,
        },
      ),
      onSuccess: (json) => ImmunisationModel.fromJson(json['data']),
    );
  }

  /// Admin: delete an immunisation record.
  Future<Either<Failure, bool>> delete(int id) async {
    return networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.delete,
        url: 'admin/immunisations/$id',
      ),
      onSuccess: (_) => true,
    );
  }
}
