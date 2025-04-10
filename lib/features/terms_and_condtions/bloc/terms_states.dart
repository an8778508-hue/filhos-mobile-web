class TermsStates {
  final TermsState aboutState;

  const TermsStates({
    this.aboutState = const TermsState(),
  });

  TermsStates copyWith({
    TermsState? aboutState,
  }) =>
      TermsStates(
        aboutState: aboutState ?? this.aboutState,
      );

  TermsStates setTermsUsState(TermsState Function(TermsState s) setter) => copyWith(
        aboutState: setter(aboutState),
      );
}

class TermsState {
  final String? data;
  final bool loading;
  final String? error;

  const TermsState({
    this.data,
    this.loading = false,
    this.error,
  });

  TermsState get fetching => const TermsState(
        loading: true,
      );

  TermsState success(String data) => TermsState(
        data: data,
      );

  TermsState failed(String error) => TermsState(
        error: error,
      );
}
