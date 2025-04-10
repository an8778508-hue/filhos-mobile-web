part of 'diary_bloc.dart';

sealed class DiaryState extends Equatable {
  const DiaryState();

  @override
  List<Object> get props => [];
}

final class DiaryInitial extends DiaryState {}

class DiaryActivitiesLoading extends DiaryState {}

class DiaryActivitiesLoaded extends DiaryState {
  final List<Activity> activities;

  const DiaryActivitiesLoaded({required this.activities});

  @override
  List<Object> get props => [activities];
}

class DiaryActivitiesError extends DiaryState {
  final Failure failure;

  const DiaryActivitiesError({required this.failure});

  @override
  List<Object> get props => [failure];
}

class MenusLoading extends DiaryState {}

class MenusLoaded extends DiaryState {
  final List<ChildMenuModel> menus;

  const MenusLoaded({required this.menus});

  @override
  List<Object> get props => [menus];
}

class MenusError extends DiaryState {
  final Failure failure;

  const MenusError({required this.failure});

  @override
  List<Object> get props => [failure];
}

class SingleMenusLoading extends DiaryState {}

class SingleMenusLoaded extends DiaryState {
  final List<ChildMenuModel> menus;

  const SingleMenusLoaded({required this.menus});

  @override
  List<Object> get props => [menus];
}

class SingleMenusError extends DiaryState {
  final Failure failure;

  const SingleMenusError({required this.failure});

  @override
  List<Object> get props => [failure];
}

class QuestionsTemplatesLoading extends DiaryState {}

class QuestionsTemplatesLoaded extends DiaryState {
  final List<QuestionCategoryTemplate> templates;

  const QuestionsTemplatesLoaded({required this.templates});

  @override
  List<Object> get props => [templates];
}

class QuestionsTemplatesError extends DiaryState {
  final Failure failure;

  const QuestionsTemplatesError({required this.failure});

  @override
  List<Object> get props => [failure];
}

class ChangeValueLoading extends DiaryState {}

class ChangeValueSucceed extends DiaryState {}

class SendQuestionsLoading extends DiaryState {}

class SendQuestionsSucceed extends DiaryState {}

class SendQuestionsError extends DiaryState {
  final Failure failure;

  const SendQuestionsError({required this.failure});

  @override
  List<Object> get props => [failure];
}

class SchoolItemsLoading extends DiaryState {}

class SchoolItemsSucceed extends DiaryState {
  final List<SchoolItem> items;

  const SchoolItemsSucceed({required this.items});

  @override
  List<Object> get props => [items];
}

class SchoolItemsError extends DiaryState {
  final Failure failure;

  const SchoolItemsError({required this.failure});

  @override
  List<Object> get props => [failure];
}
