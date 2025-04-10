import 'package:escola/features/settings/about/models/about_model.dart';

class AboutStates {
  final AboutState aboutState;

  const AboutStates({
    this.aboutState = const AboutState(),
  });

  AboutStates copyWith({
    AboutState? aboutState,
  }) =>
      AboutStates(
        aboutState: aboutState ?? this.aboutState,
      );

  AboutStates setAboutUsState(AboutState Function(AboutState s) setter) => copyWith(
        aboutState: setter(aboutState),
      );
}

class AboutState {
  final AboutModel? data;
  final String? version;
  final bool loading;
  final bool canUpdate;
  final String? error;

  const AboutState({
    this.data,
    this.version,
    this.loading = false,
    this.canUpdate = false,
    this.error,
  });

  copyWith({
    AboutModel? data,
    String? version,
    bool? loading,
    bool? canUpdate,
    String? error,
  }) {
    return AboutState(
      data: data ?? this.data,
      version: version ?? this.version,
      loading: loading ?? this.loading,
      canUpdate: canUpdate ?? this.canUpdate,
      error: error ?? this.error,
    );
  }

  AboutState get fetching => AboutState(
        loading: true,
        version: version,
    canUpdate: canUpdate,
      );

  AboutState success(AboutModel? data) => AboutState(
        data: data,
        version: version,
    canUpdate: canUpdate,
      );

  AboutState failed(String error) => AboutState(
        error: error,
        version: version,
    canUpdate: canUpdate,
      );
}
