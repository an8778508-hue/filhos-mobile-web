import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/user/bloc/user_bloc.dart';
import 'package:escola/core/utils/constants/api_const.dart';
import 'package:escola/core/utils/print.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/splash/presentation/splash_screen.dart';
import 'package:escola/my_app.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../config.dart';

/// this cubit is injected directly as a singleton
/// dont try to get it by bloc builder, selector or listener
/// instead use config builder, selector or listener
class ConfigCubit extends HydratedCubit<Config> {
  static ConfigCubit get get => di();

  ConfigCubit() : super(const Config({})) {
    // FirebaseMessaging.onBackgroundMessage(configSilentNotificationListener);
    // _silentNotificationSubscription = FirebaseMessaging.onMessage.listen(configSilentNotificationListener);
  }

  late StreamSubscription _configSubscription;
  late StreamSubscription _silentNotificationSubscription;

  final client = Client();

  Future<void> init({String? lang}) async {
    if (true) {
      final headers = {if (validString(lang)) 'lang': '$lang'};

      final response = await client.get(
        Uri.parse('${ApiConst.baseUrl}config'),
        headers: headers,
      );

      printR('Request url is :', "${ApiConst.baseUrl}config");
      printR('Request Headers is :', headers);

      final data = jsonDecode(response.body);
      final config = data?['data']?['config'];
      if (kDebugMode) {
        log('CONFIG IS');
        log(getPrettyJSONString(config));
      }
      if (validMap(config)) {
        emit(Config(config));
      }

      return;
    }

    final ref = FirebaseFirestore.instance.collection('config').doc('criarte_parents');
    // final data = await ref.get();
    // ref.update({
    //   'languages': data?['langs'],
    // });
    _emit(await ref.get());
    _configSubscription = ref.snapshots().listen(_emit);
  }

  _emit(DocumentSnapshot<Map<String, dynamic>> doc) {
    final json = doc.data() ?? {};
    emit(Config(json));
  }

  @override
  Future<void> close() async {
    await _configSubscription.cancel();
    await _silentNotificationSubscription.cancel();
    return super.close();
  }

  @override
  Config? fromJson(Map<String, dynamic> json) => Config(json);

  @override
  Map<String, dynamic>? toJson(Config state) => state.json;
}

Future<void> configSilentNotificationListener(RemoteMessage message) async {
  debugPrint('configSilentNotificationListener ${getPrettyJSONString(message.toMap())}');
  final bool isSilent = message.notification == null;

  if(message.data?['type'] == 'Teacher' ||message.data?['type'] == 'ParentModel'){
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushAndRemoveUntil( MaterialPageRoute(builder: (_) => SplashScreen()),(route) => false,);
      return;
    }
  }
  if (!isSilent) {
    return;
  }
  final configUpdated = isSuccess(message.data['update_config'].toString());
  if (!configUpdated) {
    return;
  }
  try {
    ConfigCubit.get.init(lang: UserBloc.get.state.languageWithCode);
  } catch (e) {
    debugPrint('FAILED_TO_REMOTELY_UPDATE_CONFIG $e');
  }
}
