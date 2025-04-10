import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/network/network_models.dart';
import 'package:escola/core/utils/safe_x.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/add_form/add_form_screen.dart';
import 'package:escola/features/add_form/models/add_form_model.dart';
import 'package:escola/features/add_form/models/collection_model.dart';
import 'package:escola/features/add_form/models/dropdown_model.dart';
import 'package:escola/features/add_form/models/group_model.dart';
import 'package:escola/features/add_form/models/multiselect_model.dart';
import 'package:escola/features/add_form/models/period_of_time_model.dart';
import 'package:escola/features/add_form/models/segmented_control_model.dart';
import 'package:escola/features/add_form/repo/add_form_repo.dart';
import 'package:escola/features/settings/medicines/models/medicine_model.dart';

class MedicinesRepo {
  final NetworkClientRepository networkClient;

  MedicinesRepo(this.networkClient);

  Future<Either<Failure, List<MedicineModel>>> getMedicines([int page = 1]) async {
   return await  networkClient.handleRequest(
        NetworkRequest(
          method: HttpMethod.get,
          url: '/parent/medicines',
          queryParameters: {'page': '$page'},
        ),
        onSuccess: (json) => (json['data'] as List).map((e) => MedicineModel.fromJson(e as Map<String, dynamic>)).toList());

    // final AddFormFormModel? form = f.first.fold((l) => null, (r) => r as AddFormFormModel);
    // final Map<String, dynamic>? medicinesJson = f.last.fold((l) => null, (r) => (r as Map<String, dynamic>));

    // if (form == null || medicinesJson == null) {
    //   return const Right([]);
    // }
    //
    // final fields = form.fields.fold<List<FormModel>>(
    //     <FormModel>[],
    //     (p, c) => [
    //           ...p,
    //           if (c is CollectionFormModel) ...c.items else c,
    //           if (c is GroupFormModel) ...c.items else c,
    //         ]);
    //
    // final data = medicinesJson['data'];
    // if (validList(data)) {
    //   data as List;
    //   for (int dataIndex = 0; dataIndex < data.length; dataIndex++) {
    //     final item = data[dataIndex];
    //     if (validMap(item)) {
    //       item as Map<String, dynamic>;
    //       final medicines = item['medicines'];
    //       if (validList(medicines)) {
    //         medicines as List;
    //         for (int medicineIndex = 0; medicineIndex < medicines.length; medicineIndex++) {
    //           final medicine = medicines[medicineIndex];
    //           final payload = medicine['payload'];
    //           if (validMap(payload)) {
    //             payload as Map<String, dynamic>;
    //             for (int payloadIndex = 0; payloadIndex < payload.entries.length; payloadIndex++) {
    //               final entry = payload.entries.elementAt(payloadIndex);
    //               final k = entry.key;
    //               final v = entry.value;
    //
    //               if (k != 'children' && k != 'upload_img' && k != 'attachment') {
    //                 String? selectedValue;
    //                 String? selectedTitle;
    //
    //                 for (final field in fields) {
    //                   if (field.id == entry.key) {
    //                     if (field is DropDownModel) {
    //                       final values = field.values;
    //                       final value = values.safeFirstWhere((val) => val.id == v.toString());
    //                       selectedValue = value?.title;
    //                       selectedTitle = field.title;
    //                     } else if (field is MultiSelectModel) {
    //                       final values = field.values;
    //                       final value = values.where((val) => (v as List).any((value) => value.toString() == val.id)).toList();
    //                       selectedValue = value.map((e) => e.title).join(', ');
    //                       selectedTitle = field.title;
    //                     } else if (field is SegmentedControlModel) {
    //                       final values = field.values;
    //                       final value = values.safeFirstWhere((val) => val.id == v.toString());
    //                       selectedValue = value?.title;
    //                       selectedTitle = field.title;
    //                     } else if (field is PeriodOfTimeModel) {
    //                       final values = field.values;
    //                       final value = values.where((val) => (v as List).any((value) => value.toString() == val.id)).toList();
    //                       selectedValue = value.map((e) => e.title).join(', ');
    //                       selectedTitle = field.title;
    //                     } else {
    //                       selectedValue = v;
    //                       selectedTitle = field.title;
    //                     }
    //                   }
    //                 }
    //
    //                 selectedTitle ??= '';
    //                 selectedValue ??= v.toString();
    //
    //                 // set the value here
    //                 medicinesJson['data'][dataIndex]['medicines'][medicineIndex]['payload'][k] = selectedValue;
    //               }
    //             }
    //           }
    //         }
    //       }
    //     }
    //   }
    // }
    // if (validMap(medicinesJson) && validList(medicinesJson['data'])) {
    //   return Right((medicinesJson['data'] as List).map((e) => MedicineModel.fromJson(e as Map<String, dynamic>)).toList());
    // }
    // return const Right([]);
  }

  Future<Either<Failure, void>> deleteMedicine(String id) async {
    return await networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.delete,
        url: '/parent/medicines/$id',
      ),
      onSuccess: (json) {},
    );
  }
}
