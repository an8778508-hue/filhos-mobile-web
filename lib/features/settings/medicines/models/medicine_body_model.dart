import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/add_form/models/dropdown_model.dart';
import 'package:escola/features/add_form/models/params.dart';
import 'package:escola/features/add_form/models/period_of_time_model.dart';

class MedicineBodyModel {
  final String id;
  final String childMedicineId;
  final String name;
  final String details;
  final DateTime? startingDate;
  final String potion;
  final PeriodOfTimeValueModel doseType;
  final DropDownValueModel number_of_doses;
  final String numberOfDoses;
  final PeriodOfTimeValueModel instructions;
  final List<String> time;
  final List<TempoTimeModel> tempoTimeModels;
  final PeriodOfTimeValueModel day;
  final String period_of_time;
  final String status;
  final String? notes;
  final List<UploadFileParam> image;
  final Map<String, dynamic> raw;

  const MedicineBodyModel({
    required this.id,
    required this.childMedicineId,
    required this.name,
    required this.details,
    required this.potion,
    required this.image,
    required this.status,
    required this.notes,
    required this.raw,
    required this.doseType,
    required this.tempoTimeModels,
    required this.number_of_doses,
    required this.numberOfDoses,
    required this.instructions,
    required this.time,
    required this.day,
    required this.period_of_time,
    required this.startingDate,
  });

  factory MedicineBodyModel.fromJson(Map<String, dynamic> json) {
    // final Map<String, dynamic> payload;
    // if (validMap(json['payload'])) {
    //   payload = json['payload'];
    // } else {
    //   payload = {};
    // }
    // print('MedicineBodyModel.fromJson ${json}');
    // print('MedicineBodyModel.fromJson ${validateString(json['name']?.toString())}');
    return MedicineBodyModel(
      id: validateString(json['id']?.toString()),
      childMedicineId: validateString(json['child_medicine_id']?.toString()),
      name: validateString(json['name']?.toString()),
      status: validateString(json['status']?['value'], '0'),
      notes: validateString(json['notes']?.toString()),
      potion: validateString(json['dose']?.toString()),
      doseType: PeriodOfTimeValueModel.fromJson(validateMap(json['dose_type'])),
      number_of_doses: DropDownValueModel.fromJson(validateMap(json['number_of_doses'])),
      numberOfDoses: validateString(json['number_of_doses']?.toString()),
      instructions: PeriodOfTimeValueModel.fromJson(validateMap(json['instructions'])),
      time: List<String>.of(validateList(json['tempo']).cast()),
      tempoTimeModels: validateDataList(json['tempoTimeModel'], (e) => TempoTimeModel.fromJson(e)),
      day: PeriodOfTimeValueModel.fromJson(validateMap(json['day'])),
      period_of_time: validateString(json['period_of_time']?.toString()),
      details: validateString(json['comments']?.toString()),
      startingDate: json['starting_date'] != null ? DateTime.tryParse(json['starting_date']) : null,
      image: List.from(json['upload_img'] ?? []).map((e) => UploadFileParam.fromJson(e)).toList(),
      raw: {...(json['raw'] ?? {})},
    );
  }

  Map<String, dynamic> toJson() =>
      {
        'id': id,
        'child_medicine_id': childMedicineId,
        'name': name,
        'details': details,
        'potion': potion,
        'image': image,
      };
}

class TempoTimeModel {
  final String id;
  final String medicine_item_id;
  final String title;

  const TempoTimeModel({
    required this.id,
    required this.medicine_item_id,
    required this.title,
  });

  factory TempoTimeModel.fromJson(Map<String, dynamic> json) {
    // final Map<String, dynamic> payload;
    // if (validMap(json['payload'])) {
    //   payload = json['payload'];
    // } else {
    //   payload = {};
    // }
    print('TempoTimeModel.fromJson $json');
    print('TempoTimeModel.fromJson ${validateString(json['name']?.toString())}');
    return TempoTimeModel(
      id: validateString(json['id']?.toString()),
      medicine_item_id: validateString(json['medicine_item_id']?.toString()),
      title: validateString(json['title']?.toString()),

    );
  }

  Map<String, dynamic> toJson() =>
      {
        'id': id,
        'medicine_item_id': medicine_item_id,
        'title': title,
      };
}
