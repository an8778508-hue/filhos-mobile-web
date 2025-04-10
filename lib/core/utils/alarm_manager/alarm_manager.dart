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
        final alarmSettings = AlarmSettings(
          id: id,
          dateTime: alarmDate,
          assetAudioPath: 'assets/sounds/alarm.mp3',
          loopAudio: false,
          vibrate: true,
          stopOnNotificationOpen: true,
          androidFullScreenIntent: true,
          volumeMax: false,
          fadeDuration: 3.0,
          notificationTitle: title,
          notificationBody: description,
          enableNotificationOnKill: true,
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
    try {
      if (Platform.isIOS) {
        for (int i = 0; i < ids.length; i++) {
          await NativeIOSAlarm.cancelAlarm(ids[i].toString());
        }
      } else {
        await Alarm.stopAll();
      }
    } on Exception catch (e) {
      debugPrint('$e');
    }
  }
}
