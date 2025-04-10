part of 'diary_bloc.dart';

sealed class DiaryEvent extends Equatable {
  const DiaryEvent();

  @override
  List<Object> get props => [];
}

class GetDiaryActivities extends DiaryEvent {
  final DateTime date;
  final int? childId;

  const GetDiaryActivities({
    required this.date,
    this.childId,
  });

  @override
  List<Object> get props => [date];
}

class GetMenus extends DiaryEvent {
  final DateTime? date;
  final int? childId;

  const GetMenus({
     this.date,
     this.childId,
  });

  // @override
  // List<Object> get props => [date];
}

class GetQuestionTemplates extends DiaryEvent {
  final bool filterAttendance;
  final bool filterMedia;

  const GetQuestionTemplates({
    this.filterAttendance = false,
    this.filterMedia = false,
  });
}

class AddQuetsion extends DiaryEvent {
  final Question question;
  final int categoryId;

  const AddQuetsion({
    required this.question,
    required this.categoryId,
  });

  @override
  List<Object> get props => [question, categoryId];
}

class RemoveQuestion extends DiaryEvent {
  final int questionId;
  final int categoryId;

  const RemoveQuestion({
    required this.questionId,
    required this.categoryId,
  });

  @override
  List<Object> get props => [questionId, categoryId];
}

class SendQuestionsToApi extends DiaryEvent {
  final SchoolItem item;

  const SendQuestionsToApi({
    required this.item,
  });

  @override
  List<Object> get props => [item];
}

class GetSchoolItems extends DiaryEvent {}
