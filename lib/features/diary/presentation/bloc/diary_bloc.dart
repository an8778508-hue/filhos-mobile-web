import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/local_db/local_db_repo.dart';
import 'package:escola/core/user/bloc/user_bloc.dart';
import 'package:escola/core/utils/safe_x.dart';
import 'package:escola/features/diary/data_sources/diary_repo.dart';
import 'package:escola/features/diary/models/activities.dart';
import 'package:escola/features/diary/models/category_menu_item.dart';
import 'package:escola/features/diary/models/child_menu_item.dart';
import 'package:escola/features/diary/models/question_category.dart';
import 'package:escola/features/diary/models/questions_models/image_question.dart';
import 'package:escola/features/diary/models/questions_models/question.dart';
import 'package:escola/features/diary/models/school_item.dart';
import 'package:escola/features/diary/models/tamplets/question_category_template.dart';
import 'package:escola/features/search/data_sources/search_dc.dart';
import 'package:flutter/material.dart';

part 'diary_event.dart';

part 'diary_state.dart';

class DiaryBloc extends Bloc<DiaryEvent, DiaryState> {
  final DiaryRepo diaryRepo;
  final LocalDatabaseRepo localDatabaseRepo;
  final SearchRepo searchRepo;
  List<Activity> activities = [];

  List<SchoolItem>? diaryItems;

  List<QuestionCategoryTemplate>? questionstemplates;

  Map<int, QuestionCategory> categoriesToSend = {};

  DiaryBloc({required this.searchRepo, required this.diaryRepo, required this.localDatabaseRepo})
      : super(DiaryInitial()) {
    on<DiaryEvent>((event, emit) async {
      if (event is GetDiaryActivities) {
        await _handleDiaryActivities(event, emit);
      } else if (event is GetQuestionTemplates) {
        await _handleQuestionsTemplates(event, emit);
      } else if (event is AddQuetsion) {
        await _handleAddQuestion(event, emit);
      } else if (event is SendQuestionsToApi) {
        await _handleSendQuestionsToApi(event, emit);
      } else if (event is RemoveQuestion) {
        await _handleRemoveQuestion(event, emit);
      } else if (event is GetSchoolItems) {
        await _handleSchoolItems(event, emit);
      } else if (event is GetMenus) {
        await _handleGetMenus(event, emit);
      }
    });
  }

  Future<void> _handleGetMenus(GetMenus event, Emitter<DiaryState> emit) async {
    emit(MenusLoading());
    await diaryRepo.getMenus(dateTime: event.date, childId: event.childId).then((value) {
      value.fold(
        (l) => emit(MenusError(failure: l)),
        (menus) {
          emit(MenusLoaded(menus: menus));
        },
      );
    });
  }

  Future<void> _handleSchoolItems(GetSchoolItems event, Emitter<DiaryState> emit) async {
    emit(SchoolItemsLoading());
    await diaryRepo.getSchoolItems().then((value) {
      value.fold(
        (l) => emit(SchoolItemsError(failure: l)),
        (items) {
          diaryItems = items;
          emit(SchoolItemsSucceed(items: items));
        },
      );
    });
  }

  Future<void> _handleRemoveQuestion(RemoveQuestion event, Emitter<DiaryState> emit) async {
    emit(ChangeValueLoading());
    final catgeory = categoriesToSend[event.categoryId];
    final currentQuestions = catgeory?.questions ?? [];
    // check if questions is exist
    final questionIndex = currentQuestions.indexWhere((element) {
      return element.id == event.questionId;
    });

    // remove question
    if (questionIndex != -1 && catgeory != null) {
      currentQuestions.removeAt(questionIndex);
      if (currentQuestions.isEmpty) {
        categoriesToSend.remove(event.categoryId);
      } else {
        categoriesToSend[event.categoryId] = catgeory.copyWith(
          questions: currentQuestions,
        );
      }
    }

    emit(ChangeValueSucceed());
  }

  Future<void> _handleSendQuestionsToApi(SendQuestionsToApi event, Emitter<DiaryState> emit) async {
    try {
      emit(SendQuestionsLoading());

      await _uploadImagesAndSetUrls();
      final user = UserBloc.get.state.user;

      final teacherId = (user)?.id ?? 1;

      await diaryRepo
          .sendQuestions(
        categories: categoriesToSend.values.toList(),
        item: event.item,
        teacherId: teacherId.toString(),
      )
          .then((value) {
        value.fold(
          (l) => emit(SendQuestionsError(failure: l)),
          (r) => emit(SendQuestionsSucceed()),
        );
      });
    } on Failure catch (e) {
      emit(SendQuestionsError(failure: e));
    } catch (e, s) {
      debugPrint(e.toString() + s.toString());
      emit(const SendQuestionsError(failure: ServerFailure()));
    }
  }

  Future<void> _handleAddQuestion(AddQuetsion event, Emitter<DiaryState> emit) async {
    emit(ChangeValueLoading());
    final catgeory = categoriesToSend[event.categoryId];
    final currentQuestions = catgeory?.questions ?? [];
    // check if questions is exist
    final questionIndex = currentQuestions.indexWhere((element) {
      return element.id == event.question.id;
    });
    // add or update question
    if (questionIndex != -1) {
      currentQuestions[questionIndex] = event.question;
    } else {
      currentQuestions.add(event.question);
    }
    // update category
    if (catgeory != null) {
      categoriesToSend[event.categoryId] = catgeory.copyWith(
        questions: currentQuestions,
      );
    } else {
      final currentCategory = questionstemplates?.safeFirstWhere((e) => e.id == event.categoryId);
      categoriesToSend[event.categoryId] = QuestionCategory(
        statusType: currentCategory?.statusType,
        id: event.categoryId,
        questions: currentQuestions,
        title: null,
        icon: null,
        type: currentCategory?.type,
        value: currentCategory?.value,
      );
    }

    emit(ChangeValueSucceed());
  }

  // iterate over categories and questions and upload images and set urls to the question.
  Future<void> _uploadImagesAndSetUrls() async {
    for (int categoryIndex = 0; categoryIndex < categoriesToSend.values.length; categoryIndex++) {
      final category = categoriesToSend.values.toList()[categoryIndex];
      final int length = category.questions?.length ?? 0;
      for (int questionIndex = 0; questionIndex < length; questionIndex++) {
        final question = category.questions?[questionIndex];
        if (question?.type == QuestionType.image) {
          ImagesQuestion imagesQuestion = question as ImagesQuestion;
          final images = imagesQuestion.value as List<String>;
          // if (images.isNotEmpty && isHttpLink(images.first) == false) {
          //   await diaryRepo.uploadAttachments(images).then((value) {
          //     value.fold(
          //       (l) => throw l,
          //       (imagesUrl) {
          List<MultipartFile> multipartFiles = [];
          for (int index = 0; index < images.length; index++) {
            multipartFiles.add(await MultipartFile.fromFile(
              images[index],
              filename: images[index].split('/').last,
            ));
          }
          category.questions?[questionIndex] = imagesQuestion.copyWith(images: multipartFiles.toList());
          if (category.id != null) {
            categoriesToSend[category.id!] = category;
          }
          // },
          // );
          // });
          // }
        }
      }
    }
  }

  Future<void> _handleQuestionsTemplates(GetQuestionTemplates event, Emitter<DiaryState> emit) async {
    emit(QuestionsTemplatesLoading());
    await diaryRepo
        .getCategoryTemplats(
      dateTime: DateTime.now(),
      childId: 1,
      filterAttendance: event.filterAttendance,
      filterMedia: event.filterMedia,
    )
        .then((value) {
      value.fold(
        (l) => emit(QuestionsTemplatesError(failure: l)),
        (templates) {
          questionstemplates = templates;
          emit(QuestionsTemplatesLoaded(templates: templates));
        },
      );
    });
  }

  _handleDiaryActivities(GetDiaryActivities event, Emitter<DiaryState> emit) async {
    emit(DiaryActivitiesLoading());
    await diaryRepo.getActivities(dateTime: event.date, childId: event.childId).then((value) {
      value.fold(
        (l) => emit(DiaryActivitiesError(failure: l)),
        (activities) {
          this.activities = activities;
          emit(DiaryActivitiesLoaded(activities: activities));
        },
      );
    });
  }
}
