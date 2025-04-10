import 'package:escola/core/utils/safe_x.dart';
import 'package:escola/features/add_form/bloc/add_form_state.dart';
import 'package:escola/features/add_form/models/add_form_model.dart';

bool Function(AddFormState, AddFormState) updateWhen(FormModel id) => (p, c) {
      final d1 = p.formState.data?.entries.safeFirstWhere((e) => e.key.id == id.id)?.value.value;
      final d2 = c.formState.data?.entries.safeFirstWhere((e) => e.key.id == id.id)?.value.value;
      if (d1 == null && d2 == null) {
        return false;
      }
      if (d1 != d2) {
        return true;
      }
      return false;
    };

Object? getData(AddFormState state, FormModel id) => state.formState.data?.entries.safeFirstWhere((e) => e.key.id == id.id)?.value.value;
