import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/chat/models/chat_user.dart';
import 'package:escola/features/chat/models/message.dart';
import 'package:escola/features/diary/models/child_model.dart';

abstract class ChatHelper {
  static Future<Message> buildMessageFromContent({
    required String content,
    required ChatUser sender,
    required ChatUser reciever,
    required ChildModel? child,
    required MessageType type,
  }) async {
    final sendTime = DateTime.now();
    final timeInMillis = sendTime.millisecondsSinceEpoch.toString();

    return Message(
        id: timeInMillis,
        dateTime: sendTime,
        child: child,
        timestamp: int.parse(timeInMillis),
        content: content,
        type: type,
        sender: sender,
        reciever: reciever);
  }

  static String getFileName(String url) {
    RegExp regExp = RegExp(r'.+(\/|%2F)(.+)\?.+');
    //This Regex won't work if you remove ?alt...token
    var matches = regExp.allMatches(url);
    var match = matches.elementAtOrNull(0);
    return Uri.decodeFull(match?.group(2)!??'');
  }

  static bool isVideoFile(String url) {
    try {
      final ext = getFileName(url).split(".").last;
    return isVideo(ext);
    } on Exception catch (e) {
      return false;
    }
  }
}
