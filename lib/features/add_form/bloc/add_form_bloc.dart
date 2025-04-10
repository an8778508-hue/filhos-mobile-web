import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/utils/print.dart';
import 'package:escola/core/utils/safe_x.dart';
import 'package:escola/features/add_form/add_form_screen.dart';
import 'package:escola/features/add_form/bloc/add_form_state.dart';
import 'package:escola/features/add_form/models/add_form_model.dart';
import 'package:escola/features/add_form/models/params.dart';
import 'package:escola/features/add_form/repo/add_form_repo.dart';
import 'package:escola/features/add_medicine/repo/add_medicine_repo.dart';
import 'package:escola/features/diary/models/child_model.dart';
import 'package:escola/features/settings/my_children/repo/my_children_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddFormBloc extends Cubit<AddFormState> {
  static AddFormBloc get(BuildContext context) => BlocProvider.of(context);

  final AddFormType addFormType;
  final MyChildrenRepo myChildrenRepo;
  final AddMedicineRepo addMedicineRepo;

  AddFormBloc(this.repo, this.addFormType, this.myChildrenRepo, this.addMedicineRepo) : super(const AddFormState());

  final AddFormRepo repo;

  Future fetchFields(String? id, {bool refresh = false}) async {
    emit(state.updateFetchApiState((s) => refresh ? s.asRefresh() : s.asLoading()));
    final f = await repo.fetchFields();
    f.fold(
      (l) => emit(state.updateFetchApiState((s) => s.asFailed(l))),
      (r) {
        emit(state.updateFetchApiState((s) => s.asSuccess(r)));
        if (id != null) {
          fetchForm(id);
        }
      },
    );
  }

  Future fetchForm(String id) async {
    emit(state.updateFormState((s) => s.asLoading()));
    final f = await repo.fetchForm(id);
    f.fold(
      (l) => emit(state.updateFormState((s) => s.asFailed(l))),
      (r) => emit(state.updateFormState((s) => s.asSuccess(r))),
    );
  }

  Future saveForm(String? id) async {
    emit(state.updateSaveApiState((s) => s.asLoading()));

    final form = state.formState.data ?? {};

    final f = await repo.saveForm(
      Map.fromEntries(form.entries.where((e) => validateDependency(e.key, form)).map((e) => MapEntry(e.key.id, e.value))),
      id,
    );
    f.fold(
      (l) => emit(state.updateSaveApiState((s) => s.asFailed(l))),
      (r) => emit(state.updateSaveApiState((s) => s.asSuccess())),
    );
  }
  Future saveMedicine(String? id) async {
    emit(state.updateSaveApiState((s) => s.asLoading()));

    final form = state.formState.data ?? {};

    final f = await addMedicineRepo.saveMedicine(
      Map.fromEntries(form.entries.where((e) => validateDependency(e.key, form)).map((e) => MapEntry(e.key.id, e.value))),
      id,
    );
    f.fold(
      (l) => emit(state.updateSaveApiState((s) => s.asFailed(l))),
      (r) => emit(state.updateSaveApiState((s) => s.asSuccess())),
    );
  }

  void updateForm(FormModel key, dynamic value) {
    final form = {...state.formState.data ?? {}};
    if (value == null) {
      form.remove(key);
    } else {
      form[key] = CreateFormParams(type: key.type, value: value);
    }
    // get the field whose dependency updated
    final field = form.entries.safeFirstWhere((e) => e.key.dependency?.id == key.id);
    if (field != null) {
      // remove this field
      form.removeWhere((key, value) => key.id == field.key.id);
    }
    emit(state.updateFormState((s) => s.asSuccess(Map.fromEntries(form.entries.where((e) => validateDependency(e.key, form))))));
    print('AddFormBloc.updateForm');
    print(getPrettyJSONString(state.formState.data?.map((key, value) => MapEntry(key.id, value.value))));

  }

  fetchAddMedicineData(String? id, {bool refresh = false})async{
    emit(state.copyWith(addMedicineChildrenState: state.addMedicineChildrenState.fetching));

    final List<Either<Failure, Object>> f = await Future.wait([
      myChildrenRepo.getChildren(1),
      addMedicineRepo.fetchMedicineFields(),
    ]);

    f[0].fold(
          (l) async => emit(state.copyWith(addMedicineChildrenState: state.addMedicineChildrenState.failed(l))),
          (r) async {
        emit(state.copyWith(addMedicineChildrenState: state.addMedicineChildrenState.success(r as List<ChildModel>)));
      },
    );
    f[1].fold(
          (l) async => emit(state.copyWith(addMedicineFieldsState: state.addMedicineFieldsState.failed(l))),
          (r) async {
        emit(state.copyWith(addMedicineFieldsState: state.addMedicineFieldsState.success(r as List<Map>)));
      },
    );
  }

}
