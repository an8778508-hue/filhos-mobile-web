import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/models/generic_state.dart';
import 'package:escola/features/add_form/models/add_form_model.dart';
import 'package:escola/features/add_form/models/dropdown_model.dart';
import 'package:escola/features/add_form/models/multiselect_model.dart';
import 'package:escola/features/add_form/models/params.dart';
import 'package:escola/features/add_form/models/period_of_time_model.dart';
import 'package:escola/features/add_form/models/segmented_control_model.dart';
import 'package:escola/features/diary/models/child_model.dart';

class AddFormState extends Equatable {
  final GenericDataState<Map<FormModel, CreateFormParams>> formState;
  final AddFormFetchApiState fetchApiState;
  final AddFormSaveApiState saveApiState;
  final AddMedicineChildrenState addMedicineChildrenState;
  final AddMedicineFieldsState addMedicineFieldsState;

  const AddFormState({
    this.formState = const GenericDataState<Map<FormModel, CreateFormParams>>(),
    this.fetchApiState = const AddFormFetchApiState(),
    this.saveApiState = const AddFormSaveApiState(),
    this.addMedicineChildrenState = const AddMedicineChildrenState(),
    this.addMedicineFieldsState = const AddMedicineFieldsState(),
  });

  AddFormState copyWith({
    GenericDataState<Map<FormModel, CreateFormParams>>? formState,
    AddFormFetchApiState? fetchApiState,
    AddFormSaveApiState? saveApiState,
    AddMedicineChildrenState? addMedicineChildrenState,
    AddMedicineFieldsState? addMedicineFieldsState,
  }) =>
      AddFormState(
        formState: formState ?? this.formState,
        fetchApiState: fetchApiState ?? this.fetchApiState,
        saveApiState: saveApiState ?? this.saveApiState,
        addMedicineChildrenState: addMedicineChildrenState ?? this.addMedicineChildrenState,
        addMedicineFieldsState: addMedicineFieldsState ?? this.addMedicineFieldsState,
      );

  AddFormState updateFormState(
          GenericDataState<Map<FormModel, CreateFormParams>> Function(
                  GenericDataState<Map<FormModel, CreateFormParams>> s)
              updater) =>
      copyWith(
        formState: updater(formState),
      );

  AddFormState updateFetchApiState(AddFormFetchApiState Function(AddFormFetchApiState s) updater) => copyWith(
        fetchApiState: updater(fetchApiState),
      );

  AddFormState updateSaveApiState(AddFormSaveApiState Function(AddFormSaveApiState s) updater) => copyWith(
        saveApiState: updater(saveApiState),
      );

  @override
  List<Object?> get props => [
        formState,
        fetchApiState,
        saveApiState,
        addMedicineChildrenState,
        addMedicineFieldsState,
      ];
}

class AddFormSaveApiState extends Equatable {
  final bool success;
  final bool loading;
  final Failure? failure;

  const AddFormSaveApiState({
    this.success = false,
    this.loading = false,
    this.failure,
  });

  AddFormSaveApiState asLoading() => const AddFormSaveApiState(
        loading: true,
      );

  AddFormSaveApiState asSuccess() => const AddFormSaveApiState(
        success: true,
      );

  AddFormSaveApiState asFailed(Failure failure) => AddFormSaveApiState(
        failure: failure,
      );

  @override
  List<Object?> get props => [
        loading,
        success,
        failure,
      ];
}

class AddFormFetchApiState extends Equatable {
  final AddFormFormModel? form;
  final bool loading;
  final bool refresh;
  final Failure? failure;

  const AddFormFetchApiState({
    this.form,
    this.loading = false,
    this.refresh = false,
    this.failure,
  });

  AddFormFetchApiState asLoading() => AddFormFetchApiState(
        form: form,
        loading: true,
      );

  AddFormFetchApiState asRefresh() => AddFormFetchApiState(
        form: form,
        refresh: true,
      );

  AddFormFetchApiState asSuccess(AddFormFormModel form) => AddFormFetchApiState(
        form: form,
      );

  AddFormFetchApiState asFailed(Failure failure) => AddFormFetchApiState(
        form: form,
        failure: failure,
      );

  @override
  List<Object?> get props => [
        loading,
        form,
        failure,
      ];
}

class AddMedicineChildrenState {
  final List<ChildModel> data;
  final bool loading;
  final Failure? error;

  const AddMedicineChildrenState({
    this.data = const [],
    this.loading = false,
    this.error,
  });

  AddMedicineChildrenState get fetching => const AddMedicineChildrenState(
        loading: true,
      );

  AddMedicineChildrenState success(List<ChildModel> data) => AddMedicineChildrenState(
        data: data,
      );

  AddMedicineChildrenState failed(Failure error) => AddMedicineChildrenState(
        error: error,
      );
}

class AddMedicineFieldsState {
  final List<Map> data;
  final List<DropDownValueModel> doseModels;
  final List<DropDownValueModel> number_of_dosesModels;
  final List<PeriodOfTimeValueModel> periodOfTimeModels;
  final List<SegmentedControlValueModel> instructionsModels;
  final List<SegmentedControlValueModel> periodModels;

  final bool loading;
  final Failure? error;

  const AddMedicineFieldsState({
    this.data = const [],
    this.loading = false,
    this.error,
    this.doseModels = const [],
    this.number_of_dosesModels = const [],
    this.periodOfTimeModels = const [],
    this.instructionsModels = const [],
    this.periodModels = const [],

  });

  AddMedicineFieldsState get fetching => const AddMedicineFieldsState(
        loading: true,
      );

  AddMedicineFieldsState success(List<Map> data) {
    final Map? doseMap = data.firstWhereOrNull(
          (element) => element.containsKey('dose'),
    );
    final List<Map<String, dynamic>> doseMapped =
    doseMap != null ? (doseMap['dose'] as List).cast<Map<String, dynamic>>() : [];

    final Map? number_of_dosesMap = data.firstWhereOrNull(
          (element) => element.containsKey('number_of_doses'),
    );
    final List<Map<String, dynamic>> number_of_dosesMapped =
    number_of_dosesMap != null ? (number_of_dosesMap['number_of_doses'] as List).cast<Map<String, dynamic>>() : [];

    final Map? periodOfTimeMap = data.firstWhereOrNull(
          (element) => element.containsKey('periodOfTime'),
    );
    final List<Map<String, dynamic>> periodOfTimeMapped =
    periodOfTimeMap != null ? (periodOfTimeMap['periodOfTime'] as List).cast<Map<String, dynamic>>() : [];

    final Map? instructionsMap = data.firstWhereOrNull(
          (element) => element.containsKey('instructions'),
    );
    final List<Map<String, dynamic>> instructionsMapped =
    instructionsMap != null ? (instructionsMap['instructions'] as List).cast<Map<String, dynamic>>() : [];

    final Map? periodMap = data.firstWhereOrNull(
          (element) => element.containsKey('period'),
    );
    final List<Map<String, dynamic>> periodMapped =
    periodMap != null ? (periodMap['period'] as List).cast<Map<String, dynamic>>() : [];

    return AddMedicineFieldsState(
      data: data,
      doseModels: doseMapped
              .map((e) => DropDownValueModel(id: e['id'].toString(), title: e['title']))
              .toList(),
      number_of_dosesModels: number_of_dosesMapped
              .map((e) => DropDownValueModel(id: e['id'].toString(), title: e['title']))
              .toList(),
      periodOfTimeModels: periodOfTimeMapped
              .map((e) => PeriodOfTimeValueModel(id: e['id'].toString(), title: e['title']))
              .toList(),
      instructionsModels: instructionsMapped
              .map((e) => SegmentedControlValueModel(id: e['id'].toString(), title: e['title']))
              .toList(),
      periodModels: periodMapped
              .map((e) => SegmentedControlValueModel(id: e['id'].toString(), title: e['title']))
              .toList(),

    );
  }

  AddMedicineFieldsState failed(Failure error) => AddMedicineFieldsState(
        error: error,
      );
}
