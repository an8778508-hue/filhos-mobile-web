import 'package:equatable/equatable.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/diary/models/child_model.dart';
import 'package:escola/features/settings/medicines/models/medicine_body_model.dart';

class MedicinePrescriptionModel extends Equatable {
  final ChildModel? child;
  final List<PrescriptionModel> feed;

  const MedicinePrescriptionModel({
    required this.child,
    required this.feed,
  });

  factory MedicinePrescriptionModel.fromJson(Map<String, dynamic> json) => MedicinePrescriptionModel(
        child: validateDataModel(json['child'], ChildModel.fromJson),
        feed: validateDataList(json['reminders'], PrescriptionModel.fromJson),
      );

  @override
  List<Object?> get props => [
        child,
        feed,
      ];
}

class PrescriptionModel extends Equatable {
  final String id;
  final MedicineBodyModel medicineBodyModel;
  final String time;
  final DoctorModel? doctor;

  const PrescriptionModel({
    required this.id,
    required this.medicineBodyModel,
    required this.time,
    required this.doctor,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) => PrescriptionModel(
        id: validateString(json['id'].toString()),
    medicineBodyModel: MedicineBodyModel.fromJson(json['medicine']??{}),
        time: [
          if (validString(json['date'].toString())) validateString(json['date'].toString()),
          if (validString(json['time'].toString())) validateString(json['time'].toString()),
        ].join(' '),
        doctor: validateDataModel(json['approved_by'], DoctorModel.fromJson),
      );

  @override
  List<Object?> get props => [
        id,
    medicineBodyModel,
        time,
        doctor,
      ];
}

class DoctorModel extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String avatar;

  const DoctorModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.avatar,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) => DoctorModel(
        id: validateString(json['id'].toString()),
        name: validateString(json['name'].toString()),
        phone: validateString(json['phone'].toString()),
        avatar: validateString(json['avatar'].toString()),
      );

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        avatar,
      ];
}
