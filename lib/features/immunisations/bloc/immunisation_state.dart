import 'package:escola/core/models/generic_state.dart';
import 'package:escola/features/immunisations/model/immunisation_model.dart';

class ImmunisationState {
  final GenericListState<ImmunisationModel> immunisationsState;

  const ImmunisationState({
    this.immunisationsState = const GenericListState<ImmunisationModel>(),
  });

  ImmunisationState copyWith({
    GenericListState<ImmunisationModel>? immunisationsState,
  }) =>
      ImmunisationState(
        immunisationsState: immunisationsState ?? this.immunisationsState,
      );

  ImmunisationState updateImmunisationsState(
          GenericListState<ImmunisationModel> Function(GenericListState<ImmunisationModel> s) update) =>
      copyWith(immunisationsState: update(immunisationsState));

  List<ImmunisationModel> get data => immunisationsState.data;

  bool get hasImmunisations => data.isNotEmpty;
}
