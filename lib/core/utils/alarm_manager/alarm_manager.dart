import 'dart:io';

import 'package:alarm/alarm.dart';
import 'package:escola/core/custom_packages/native_alarm/native_alarm.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/local_db/local_db_repo.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/alarm_manager/alarm_repo.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/flavors/app_flavors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';

import '../debouncer.dart';

final debouncer = Debouncer();

getAlarms(BuildContext context) {
  debouncer.runLazy(
    () {
      if (context.isProfessors) {
        di<AlarmManager>().getAlarms(context);
      }
    },
    500,
  );
}

class AlarmManager {
  final AlarmRepo alarmRepo;

  AlarmManager(this.alarmRepo);

  Future init() async {
    if (Platform.isAndroid) {
      await Alarm.init();
    }
  }

  List<int> ids = [];

  Future getAlarms(BuildContext context) async {
    ids = (await di<LocalDatabaseRepo>().read(key: 'alarm_ids')) ?? [];
    final response = await alarmRepo.getAlarms();
    response.fold((l) => null, (models) async {
      await removeAllAlarms();
      ids.clear();
      ids.addAll(models.map((e) => int.tryParse(validateString(e.id))).where((e) => e != null).cast<int>().toList());
      await di<LocalDatabaseRepo>().write(key: 'alarm_ids', value: ids);
      for (int index = 0; index < models.length; index++) {
        final model = models[index];
        final id = int.tryParse(validateString(model.id));
        if (model.date != null && id != null) {
          if (context.mounted) {
            await setAlarm(
              id: id,
              title: LocalizationKeys.medicine_notification_title.tr(context),
              description: LocalizationKeys.medicine_notification_desc.tr(context),
              alarmDate: model.date!,
            );
          }
        }
      }
    });
  }

  /// On Android 12+ (API 31+), exact alarms require `SCHEDULE_EXACT_ALARM`
  /// (user-revocable) or `USE_EXACT_ALARM` (auto-granted on API 33+ for
  /// alarm-clock / medication reminder use cases). If neither is granted we
  /// skip scheduling rather than silently demoting to an inexact alarm that
  /// would fire late and miss the medication window.
  Future<bool> _ensureExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.scheduleExactAlarm.status;
    if (status.isGranted) return true;
    final result = await Permission.scheduleExactAlarm.request();
    if (!result.isGranted) {
      debugPrint('[AlarmManager] SCHEDULE_EXACT_ALARM not granted — skipping alarm');
    }
    return result.isGranted;
  }

  setAlarm({
    required int id,
    required String title,
    required String description,
    required DateTime alarmDate,
  }) async {
    if (alarmDate.isAfter(DateTime.now())) {
      if (Platform.isIOS) {
        await NativeIOSAlarm.setAlarm(id.toString(), alarmDate, title, description);
      } else {
        if (!await _ensureExactAlarmPermission()) return;
        final alarmSettings = AlarmSettings(
          id: id,
          dateTime: alarmDate,
          assetAudioPath: 'assets/sounds/alarm.mp3',
          loopAudio: false,
          vibrate: true,
          androidFullScreenIntent: true,
          volumeSettings: VolumeSettings.fade(
            fadeDuration: Duration(seconds: 3),
          ),
          notificationSettings: NotificationSettings(
            title: title,
            body: description,
          ),
        );
        await Alarm.set(alarmSettings: alarmSettings);
      }
      ids.add(id);
      await di<LocalDatabaseRepo>().write(key: 'alarm_ids', value: ids);
    }
  }

  removeAlarm({
    required String id,
  }) async {
    try {
      final id0 = int.tryParse(validateString(id));
      if (id0 != null) {
        if (Platform.isIOS) {
          await NativeIOSAlarm.cancelAlarm(id.toString());
        } else {
          await Alarm.stop(id0);
        }
        ids.remove(id0);
        await di<LocalDatabaseRepo>().write(key: 'alarm_ids', value: ids);
      }
    } on Exception catch (e) {
      debugPrint('$e');
    }
  }

  removeAllAlarms() async {
    // The `alarm` plugin and `dart:io` Platform have no web implementation —
    // `Platform.isIOS` raises an UnsupportedError (an Error, not an Exception)
    // on web, so guard the whole thing and catch broadly (not just Exception).
    if (kIsWeb) return;
    try {
      if (Platform.isIOS) {
        for (int i = 0; i < ids.length; i++) {
          await NativeIOSAlarm.cancelAlarm(ids[i].toString());
        }
      } else {
        await Alarm.stopAll();
      }
    } catch (e) {
      debugPrint('$e');
    }
  }
}
