import 'package:flutter/foundation.dart';

@immutable
abstract class EditProfileStates {
  const EditProfileStates();
}

class InitialEditProfileState extends EditProfileStates {}

class LoadingEditProfileState extends EditProfileStates {}
class FetchedEditProfileState extends EditProfileStates {}

class SuccessEditProfileState extends EditProfileStates {
  // final UserModel user;

  // const SuccessEditProfileState(this.user);
}

class ErrorEditProfileState extends EditProfileStates {
  final String error;

  const ErrorEditProfileState(this.error);
}
