import 'package:escola/core/models/user_model.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/settings/medicines/models/medicine_body_model.dart';

class MedicineModel {
  final UserModel? userModel;
  final List<MedicineBodyModel> medicines;
  final String created_at;

  const MedicineModel({
    required this.userModel,
    required this.medicines,
    required this.created_at,
  });

  factory MedicineModel.fromJson(Map<String, dynamic> json) => MedicineModel(
        userModel: validateDataModel(json['child'], (e) => UserModel.fromJson(e)),
        medicines: validateDataList(json['medicines'], (e) => MedicineBodyModel.fromJson(e)),
        created_at: validateString(json['created_at']?.toString()),
      );
}
