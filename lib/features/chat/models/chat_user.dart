import 'package:equatable/equatable.dart';
import 'package:escola/core/models/user_model.dart';

class ChatUser extends Equatable {
  final String id;
  final String? name;
  final String? avatar;
  final UserType? type;

  const ChatUser({required this.id, required this.name, required this.avatar, required this.type});

  @override
  List<Object?> get props => [id, name, avatar, type];

  // toJson
  toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'type': type.toTypeString(),
    };
  }

  // from UserModel
  factory ChatUser.fromUserModel(UserModel user) {
    return ChatUser(id: user.id, name: user.name, avatar: user.image, type: user.type);
  }

  // fromJson
  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'].toString(),
      name: json['name'],
      avatar: json['avatar'],
      type: json['type'].toString().toUserType(),
    );
  }

  // copyWith
  ChatUser copyWith({
    String? id,
    String? token,
    String? name,
    String? avatar,
    UserType? type,
  }) {
    return ChatUser(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      type: type ?? this.type,
    );
  }
}
