import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
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
      : super(_initialState()) {
    ConfigCubit.get.init(lang: state.languageWithCode);
  }

  /// Builds the initial state from the device locale. When the device is set to
  /// Arabic, the app defaults to Arabic ('ar' / 'ar_EG'); otherwise it keeps the
  /// historical Portuguese default. Use `PlatformDispatcher.instance.locale`
  /// (from `dart:ui`) instead of `Platform.localeName` (from `dart:io`) because
  /// the latter throws on web.
  static UserState _initialState() {
    final resolved = resolveInitialLanguage(
      PlatformDispatcher.instance.locale.toString(),
    );
    return UserState(
      language: resolved.language,
      languageWithCode: resolved.languageWithCode,
    );
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
    // Clear persisted auth FIRST, then emit the null state. This is what drives
    // the logout navigation (the UserListener fires when user becomes null), so
    // it must happen unconditionally — the best-effort platform cleanup below
    // can throw (notably on web, where the native alarm plugin / dart:io
    // `Platform` checks raise UnsupportedError) and must never abort logout.
    try {
      await localDatabaseRepo.removeUser();
      // removeUser() only drops the user record; the auth token is a separate
      // Hive key, so clear it explicitly or the next login keeps the old token.
      await localDatabaseRepo.delete(key: LocalKeys.tokenKey);
    } catch (e) {
      debugPrint('logout: clearing local storage failed: $e');
    }

    emit(state.copyWith(user: null, userNullable: true));

    // --- best-effort cleanup; failures here must not affect logout ---
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('logout: firebase signOut failed: $e');
    }
    // The `alarm` plugin has no web implementation; calling it on web throws.
    if (!kIsWeb) {
      try {
        await di<AlarmManager>().removeAllAlarms();
      } catch (e) {
        debugPrint('logout: removeAllAlarms failed: $e');
      }
    }
    // Drop the FCM token so pushes intended for the previous user don't reach
    // the next user on this device (LGPD cross-account leak).
    try {
      await NotificationService.clearToken();
    } catch (e) {
      debugPrint('logout: clearToken failed: $e');
    }
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
