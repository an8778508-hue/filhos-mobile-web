import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:escola/core/config/config.dart';

part 'main_event.dart';
part 'main_state.dart';

class MainBloc extends Bloc<MainEvent, MainState> {
  String currentId = PageID.home.name;
  MainBloc() : super(MainInitial()) {
    on<MainEvent>((event, emit) async {
      if (event is ChangePage && event.id != currentId) {
        emit(ChangePageLading());
        currentId = event.id;
        await Future.delayed(const Duration(milliseconds: 100));
        emit(ChangePageSucceed(selectedPage: event.id));
      }
    });
  }
}
