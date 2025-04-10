import 'package:escola/features/settings/about/bloc/about_events.dart';
import 'package:escola/features/settings/about/bloc/about_states.dart';
import 'package:escola/features/settings/about/repo/about_repo.dart';
import 'package:flutter_app_version_checker/flutter_app_version_checker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutBloc extends Bloc<AboutEvents, AboutStates> {
  final AboutRepo myAboutRepo;

  AboutBloc({
    required this.myAboutRepo,
  }) : super(const AboutStates()) {
    on<SubmitAboutEvent>(
      (event, emit) async {},
    );
    on<FetchAbout>(
      (event, emit) async {
        emit(state.setAboutUsState((s) => s.fetching));
        try {
          PackageInfo packageInfo = await PackageInfo.fromPlatform();
          String version = packageInfo.version;
          final _checker = AppVersionChecker();
          final canUpdateChecker = await _checker.checkUpdate();

          emit(state.copyWith(
              aboutState: state.aboutState.copyWith(loading: false,version: version, canUpdate: canUpdateChecker.canUpdate)));
        } on Exception catch (e) {
          print('AboutBloc.AboutBloc Exception $e');
        }

        // final f = await myAboutRepo.getAbout();
        // f.fold(
        //   (l) async => emit(state.setAboutUsState((s) => s.failed(l.message))),
        //   (r) async {
        //     emit(state.setAboutUsState((s) => s.success(r)));
        //   },
        // );
      },
    );
  }
}
