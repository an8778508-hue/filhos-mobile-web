import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:escola/core/config/cubit/cubit.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/local_db/local_db_repo.dart';
import 'package:escola/core/models/user_model.dart';
import 'package:escola/core/notifications_service/notifications_service.dart';
import 'package:escola/core/user/bloc/user_state.dart';
import 'package:escola/core/user/data_source/user_repo.dart';
import 'package:escola/core/utils/alarm_manager/alarm_manager.dart';
import 'package:escola/core/utils/lang_utils.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

class UserBloc extends HydratedCubit<UserState> {
  static UserBloc get get => di();
  final LocalDatabaseRepo localDatabaseRepo;
  final UserRepo userRepo;

  UserBloc(this.localDatabaseRepo, this.userRepo)
      : super(UserState(
          // initial device language. Use `PlatformDispatcher.instance.locale`
          // (from `dart:ui`) instead of `Platform.localeName` (from
          // `dart:io`) because the latter throws on web.
          language: parseLang(PlatformDispatcher.instance.locale.toString()),
          languageWithCode: parseLang(PlatformDispatcher.instance.locale.toString()),
        )) {
    ConfigCubit.get.init(lang: state.languageWithCode);
  }

  updateDeviceToken() async {
    final deviceToken = await NotificationService.getToken();

    String? uuid;

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    // Web has no concept of vendor / Android id; `Platform.isIOS` throws on
    // web. Use a web-specific id from device_info_plus, or fall back to a
    // synthesized one keyed off browser + a timestamp.
    if (kIsWeb) {
      try {
        final webDeviceInfo = await deviceInfo.webBrowserInfo;
        uuid = webDeviceInfo.userAgent;
      } catch (_) {
        uuid = 'web-${DateTime.now().millisecondsSinceEpoch}';
      }
    } else if (Platform.isIOS) {
      final iosDeviceInfo = await deviceInfo.iosInfo;
      uuid = iosDeviceInfo.identifierForVendor;
    } else {
      final androidDeviceInfo = await deviceInfo.androidInfo;
      uuid = androidDeviceInfo.id;
    }

    print('UserBloc.updateDeviceToken $deviceToken');
    if (deviceToken != null && uuid != null) {
      await userRepo.updateDeviceToken(deviceToken, null, uuid).then(
            (value) => value.fold((failure) => null, (user) => null),
          );
    }
  }

  Future<void> getUserData() async {
    final String? oldToken = state.user?.accessToken;
    await userRepo.getUser().then(
          (value) => value.fold(
            (failure) => null,
            (user) async {
              // await localDatabaseRepo.saveUser(user,oldToken);
              emit(state.copyWith(user: user.copyWith(accessToken: oldToken)));
              print('UserBloc.getUserData oldToken $oldToken');
              print('UserBloc.getUserData accessToken ${state.user?.accessToken}');
            },
          ),
        );
  }

  loggedIn(UserModel user) async {
    // await localDatabaseRepo.saveUser(user);
    emit(state.copyWith(
      user: user,
    ));
  }

  Future<void> _signOutCleanup() async {
    await localDatabaseRepo.removeUser();
    await FirebaseAuth.instance.signOut();
    await di<AlarmManager>().removeAllAlarms();
    // Drop the FCM token so pushes intended for the previous user don't reach
    // the next user on this device (LGPD cross-account leak).
    await NotificationService.clearToken();
    emit(state.copyWith(user: null, userNullable: true));
  }

  loggedOut() => _signOutCleanup();

  deleteAccount() => _signOutCleanup();

  selectLang(String code,String codeWithLocale) async {
    final oldLang = state.language;
    emit(state.copyWith(language: code,languageWithCode: codeWithLocale));

    if (oldLang != code) {
     await ConfigCubit.get.init(lang: codeWithLocale);
     await Future.delayed(const Duration(milliseconds: 150));
    }
  }

  @override
  UserState? fromJson(Map<String, dynamic> json) => UserState(
        user: json['user'] is Map<String, dynamic>
            ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
            : null,
        language: validateString(json['language']?.toString(), 'pt'),
        languageWithCode: validateString(json['languageWithCode']?.toString(), 'pt_BR'),
      );

  @override
  Map<String, dynamic>? toJson(UserState state) => {
        'user': state.user?.toJson(),
        'language': state.language,
        'languageWithCode': state.languageWithCode,
      };
}
