import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/local_db/local_db_repo.dart';
import 'package:escola/core/utils/alarm_manager/alarm_manager.dart';
import 'package:escola/core/utils/bloc_observer.dart';
import 'package:escola/firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

bool clearCache = false;

Future initDependencies() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Web has no filesystem, so HydratedBloc uses IndexedDB via the special
  // `HydratedStorageDirectory.web` sentinel. Native uses the OS app docs dir.
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorageDirectory.web
        : HydratedStorageDirectory((await getApplicationDocumentsDirectory()).path),
  );

  if (clearCache) {
    await HydratedBloc.storage.clear();
  }

  // initialize firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase.initializeApp failed: $e');
  }

  // Only activate App Check in release mode. On web, `playIntegrity` does
  // not apply — would need `ReCaptchaV3Provider('site-key')`. See
  // specs/web-setup.md §4 for the external setup. Skipping on web until
  // the reCAPTCHA site key is wired.
  if (kReleaseMode && !kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
    );
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // clear firebase cache
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false);

// initialize dependency injection
  await dependencyInjection();

  if (clearCache) {
    await di<LocalDatabaseRepo>().clearDB();
  }

  // Native-only: the `alarm` package has no web implementation and the
  // current init path uses `Platform.isAndroid` (dart:io) which behaves
  // oddly on web. Medicine reminders are a no-op on web.
  if (!kIsWeb) {
    await di<AlarmManager>().init();
  }

  // use this to upload local translations to remote firebase config
  // await uploadTranslations();

// initialize local database
  await di<LocalDatabaseRepo>().initDB();

  // initialize bloc observer
  Bloc.observer = SimpleBlocObserver();
}

Future uploadTranslations() async {
  await uploadTranslation([
    'en',
    'ar',
    'pt',
  ]);
  debugPrint('Translations uploaded successfully');
}

Future uploadTranslation(List<String> langs) async {
  final Map<String, dynamic> json = {};
  for (final lang in langs) {
    json[lang] = await rootBundle.loadString('assets/langs/$lang.json').then((value) => jsonDecode(value));
  }
  await FirebaseFirestore.instance.collection('config').doc('criarte_parents').update({
    'translations': json,
  });
}
