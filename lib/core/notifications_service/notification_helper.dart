import 'dart:convert';

import 'package:escola/core/user/bloc/user_bloc.dart';
import 'package:escola/core/utils/funuctions/widget_functions.dart';
import 'package:escola/features/chat/models/chat_user.dart';
import 'package:escola/features/chat/presentation/chat_screen.dart';
import 'package:escola/features/diary/models/child_model.dart';
import 'package:escola/features/diary/presentation/dairy_screen.dart';
import 'package:escola/features/notifications/notifications_page.dart';
import 'package:escola/features/settings/accept_event/accept_events.dart';
import 'package:escola/features/settings/events/event_screen.dart';
import 'package:escola/my_app.dart';
import 'package:flutter/foundation.dart';

class NotificationHelper {
  /// `sender` / `child` in the FCM payload may arrive as either a JSON string
  /// (FCM flattens `data:` to strings) or as a nested object (direct testing
  /// or some custom backends). Tolerate both.
  static Map<String, dynamic>? _parseEmbedded(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        return decoded is Map<String, dynamic> ? decoded : null;
      } catch (e) {
        debugPrint('FCM embedded payload was not JSON: $e');
        return null;
      }
    }
    return null;
  }

  static Future handleNotificationTap({required Map<String, dynamic> data}) async {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;

    // Approval gate — a pending-approval user must never be routed into a
    // protected feature via a push tap.
    final user = UserBloc.get.state.user;
    if (user == null) return; // not logged in: splash will route correctly
    if (user.isApproval == false) return;

    final type = (data['type']) ?? (data['eventable_type']);
    final id = (data['id']) ?? (data['eventable_id']);

    if (type == "chat") {
      final senderData = _parseEmbedded(data['sender']);
      final childData = _parseEmbedded(data['child']);
      final ChildModel? child = childData == null ? null : ChildModel.fromJson(childData);
      final ChatUser? contact = senderData == null ? null : ChatUser.fromJson(senderData);
      if (contact != null) {
        await WidgetFunctions.navigateTo(ctx, ChatScreen(contact: contact, child: child));
      }
    } else if (type == "event" || type.toString().toLowerCase() == "events") {
      if (id != null) {
        await WidgetFunctions.navigateTo(ctx, AcceptEventScreen(eventId: id));
      } else {
        await WidgetFunctions.navigateTo(ctx, const EventsScreen());
      }
    } else if (type == "diary" || type == "FieldAnswer") {
      await WidgetFunctions.navigateTo(ctx, const DiaryScreen());
    } else {
      // Unknown type — drop into the inbox so the tap isn't lost entirely.
      await WidgetFunctions.navigateTo(ctx, const NotificationsPage());
    }
  }
}
