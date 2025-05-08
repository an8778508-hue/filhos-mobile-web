import 'dart:convert';

import 'package:escola/core/utils/funuctions/widget_functions.dart';
import 'package:escola/features/chat/models/chat_user.dart';
import 'package:escola/features/chat/presentation/chat_screen.dart';
import 'package:escola/features/diary/models/child_model.dart';
import 'package:escola/features/diary/presentation/dairy_screen.dart';
import 'package:escola/features/settings/accept_event/accept_events.dart';
import 'package:escola/features/settings/events/event_screen.dart';
import 'package:escola/my_app.dart';
import 'package:flutter/cupertino.dart';

class NotificationHelper {
  static Future handleNotificationTap({required Map<String, dynamic> data}) async {
    final type = (data?['type'])??(data['eventable_type']);
    final id = (data['id'])?? (data['eventable_id']);
    final eventableId = (data['eventable_id']);
    debugPrint("NotificationHelper.handleNotificationTap: $data");

    if (type == "chat") {
      final senderData = data['sender'] == null ? null : jsonDecode(data['sender']);
      final childData = data['child'] == null ? null : jsonDecode(data['child']);
      final ChildModel? child = childData == null ? null : ChildModel.fromJson(childData);
      final ChatUser? contact = senderData == null ? null : ChatUser.fromJson(senderData);
      if (contact != null && navigatorKey.currentContext != null) {
        await WidgetFunctions.navigateTo(navigatorKey.currentContext!, ChatScreen(contact: contact, child: child));
      }
    } else if (type == "event"|| type.toString().toLowerCase() == "events") {
      if(eventableId != null){
        await WidgetFunctions.navigateTo(navigatorKey.currentContext!, AcceptEventScreen(eventId: eventableId.toString()));
      }else{
      await WidgetFunctions.navigateTo(navigatorKey.currentContext!, const EventsScreen());
      }
    } else if (type == "diary"|| type == "FieldAnswer") {
      await WidgetFunctions.navigateTo(navigatorKey.currentContext!, const DiaryScreen());
    }
  }
}
