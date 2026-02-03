
// class Conversation extends Equatable {
//   final List<Message> messages;
//
//   const Conversation({required this.messages});
//
//   @override
//   List<Object?> get props => [messages];
//
//   // toJson
//   toJson() {
//     return {
//       'messages': messages.map((e) => e.toJson()).toList(),
//     };
//   }
//
//   // fromJson
//   factory Conversation.fromJson(Map<String, dynamic> json) {
//     return Conversation(
//       messages: json['messages'].map((e) => Message.fromJson(e)).toList(),
//     );
//   }
// }
