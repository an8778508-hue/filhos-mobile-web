import 'package:equatable/equatable.dart';
import 'package:escola/core/models/user_model.dart';

class UserState extends Equatable {
  final UserModel? user;
  final String language;
  final String languageWithCode;

  const UserState({
    this.user,
    required this.language,
    required this.languageWithCode,
  });

  UserState copyWith({
    UserModel? user,
    String? language,
    String? languageWithCode,
    bool userNullable = false,
  }) =>
      UserState(
        user: userNullable ? user : user ?? this.user,
        language: language ?? this.language,
        languageWithCode: languageWithCode ?? this.languageWithCode,
      );

  @override
  List<Object?> get props => [
        user,
        language,
    languageWithCode,
      ];
}
