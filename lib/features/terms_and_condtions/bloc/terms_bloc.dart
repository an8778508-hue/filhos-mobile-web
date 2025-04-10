import 'package:flutter_bloc/flutter_bloc.dart';

import '../repo/terms_repo.dart';
import 'terms_events.dart';
import 'terms_states.dart';

class TermsBloc extends Bloc<TermsEvents, TermsStates> {
  final TermsRepo myTermsRepo;

  TermsBloc({
    required this.myTermsRepo,
  }) : super(const TermsStates()) {
    on<FetchTerms>(
      (event, emit) async {
        emit(state.setTermsUsState((s) => s.fetching));
        final f = await myTermsRepo.getTerms();
        f.fold(
          (l) async => emit(state.setTermsUsState((s) => s.failed(l.message))),
          (r) async {
            emit(state.setTermsUsState((s) => s.success(r)));
          },
        );
      },
    );
    on<FetchPrivacy>(
      (event, emit) async {
        emit(state.setTermsUsState((s) => s.fetching));
        final f = await myTermsRepo.getPrivacy();
        f.fold(
          (l) async => emit(state.setTermsUsState((s) => s.failed(l.message))),
          (r) async {
            emit(state.setTermsUsState((s) => s.success(r)));
          },
        );
      },
    );
  }
}
