import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/user/bloc/user_bloc.dart';
import 'package:escola/core/user/data_source/user_repo.dart';

part 'splash_events.dart';
part 'splash_states.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final UserBloc userBloc;
  final UserRepo userRepo;
  SplashBloc(this.userBloc, this.userRepo) : super(SplashInitial()) {
    on<SplashEvent>((event, emit) async {
      if (event is FetchSplashEvent) {
        try {
          final bool hasUser = userBloc.state.user != null;
          if (hasUser) {
            // final localUser = await localDatabase.getUser();
            final String? oldToken = userBloc.state.user?.accessToken;
            final remoteUserResult = await userRepo.getUser();
            return remoteUserResult.fold((l) async {
              // await UserBloc.get.loggedIn(localUser!);
              // emit(SplashSuccess(hasUser));
              emit(SplashFailure(l));
            }, (remoteUser) async {
              await UserBloc.get.loggedIn(remoteUser.copyWith(accessToken: oldToken));
              emit(SplashSuccess(hasUser));
            });
          } else {
            emit(SplashSuccess(hasUser));
          }
        } catch (e) {
          emit(SplashFailure(ServerFailure(message: e.toString())));
          // emit(const SplashSuccess(false));
        }
      }
    });
  }
}
