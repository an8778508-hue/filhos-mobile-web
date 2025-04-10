import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/user/bloc/user_bloc.dart';
import 'package:escola/features/add_address/repo/add_address_repo.dart';
import 'package:escola/features/settings/edit_profile/models/class_model.dart';
import 'package:escola/features/settings/edit_profile/models/state_model.dart';
import 'package:escola/features/settings/edit_profile/models/title_model.dart';
import 'package:escola/features/settings/edit_profile/repo/edit_profile_repo.dart';
import 'package:escola/flavors/app_flavors.dart';
import 'package:escola/my_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'edit_profile_events.dart';
import 'edit_profile_states.dart';

class EditProfileBloc extends Bloc<EditProfileEvents, EditProfileStates> {
  static EditProfileBloc get(BuildContext context) => BlocProvider.of(context);

  final EditProfileRepo editProfileRepo;
  ValueNotifier<List<TitleModel>> titles = ValueNotifier([]);
  // ValueNotifier<List<ClassModel>> classes = ValueNotifier([]);

  EditProfileBloc({
    required this.editProfileRepo,
  }) : super(InitialEditProfileState()) {
    on<FetchEditProfileEvent>(
      (event, emit) async {
        emit(LoadingEditProfileState());
        final List<EditProfileStates?> results = await Future.wait([
          // editProfileRepo.getClasses().then((value) => value.fold(
          //       (l) => ErrorEditProfileState(l.message),
          //       (r) {
          //         classes.value = r;
          //         return null;
          //       },
          //     )),
          if(mainKey.currentContext?.isProfessors == true)
          editProfileRepo.getTitles().then((value) => value.fold(
                (l) => ErrorEditProfileState(l.message),
                (r) {
                  titles.value = r;
                  return null;
                },
              )),
        ]);

        bool success = true;

        for (final result in results) {
          if (result != null) {
            success = false;
            emit(result);
            break;
          }
        }

        if (success) {
          emit(FetchedEditProfileState());
        }
      },
    );

    on<SubmitEditProfileEvent>(
      (event, emit) async {
        emit(LoadingEditProfileState());
        final response = await editProfileRepo.updateProfile(
          phone: event.phone,
          name: event.name,
          email: event.email,
          cpf: event.cpf,
          avatar: event.avatar,
          phones: event.phones,
          emails: event.emails,
          // classes: event.classes,
          title:  event.title,
          gender:  event.gender,
        );
        return response.fold(
          (l) {
            print('EditProfileBloc.EditProfileBloc $l');
            emit(ErrorEditProfileState(l.message));
          },
          (r) async {
            await di<UserBloc>().getUserData();
            emit(SuccessEditProfileState());
          },
        );
      },
    );
  }
}
