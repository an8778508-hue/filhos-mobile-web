import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/local_db/local_db_repo.dart';
import 'package:escola/core/utils/alarm_manager/alarm_manager.dart';
import 'package:escola/core/utils/bloc_observer.dart';
import 'package:escola/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

bool clearCache = false;

Future initDependecies() async {
  WidgetsFlutterBinding.ensureInitialized();

  HydratedBloc.storage = await HydratedStorage.build(storageDirectory: await getApplicationDocumentsDirectory());

  if (clearCache) {
    await HydratedBloc.storage.clear();
  }

  // initialize firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // clear firebase cache
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false);

// initialize dependency injection
  await dependencyInjection();

  if (clearCache) {
    await di<LocalDatabaseRepo>().clearDB();
  }

  await di<AlarmManager>().init();

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
