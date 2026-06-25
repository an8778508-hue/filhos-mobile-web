import 'package:escola/core/models/generic_state.dart';
import 'package:escola/features/allergies/model/allergy_model.dart';

class AllergyState {
  final GenericListState<AllergyModel> allergiesState;

  const AllergyState({
    this.allergiesState = const GenericListState<AllergyModel>(),
  });

  AllergyState copyWith({
    GenericListState<AllergyModel>? allergiesState,
  }) =>
      AllergyState(
        allergiesState: allergiesState ?? this.allergiesState,
      );

  AllergyState updateAllergiesState(
          GenericListState<AllergyModel> Function(GenericListState<AllergyModel> s) update) =>
      copyWith(allergiesState: update(allergiesState));

  List<AllergyModel> get data => allergiesState.data;

  bool get hasAllergies => data.isNotEmpty;
}
