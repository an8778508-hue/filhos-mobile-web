import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/features/diary/models/activities.dart';
import 'package:escola/features/diary/models/category_menu_item.dart';
import 'package:escola/features/diary/models/child_menu_item.dart';
import 'package:escola/features/diary/models/question_category.dart';
import 'package:escola/features/diary/models/school_item.dart';
import 'package:escola/features/diary/models/tamplets/question_category_template.dart';

abstract class DiaryRepo {
  final String activitiesEndpoint = "/parent/timeline/view";
  final String questionsDataEndpoint = "teacher/questions";
  final String sendQuestionsEndpoint = "teacher/questions/answers";
  final String diaryItemsEndpoint = "/teacher/questions/data";
  final String searchEndpoint = "parent/children";
  final String uploadFiles = "/files/upload";
  final String menusEndpoint = "parent/children/menus";

  Future<Either<Failure, List<Activity>>> getActivities({required DateTime dateTime, required int? childId});

  Future<Either<Failure, List<QuestionCategoryTemplate>>> getCategoryTemplats({
    required DateTime dateTime,
    required int? childId,
    bool filterAttendance = false,
    bool filterMedia = false,
  });

  Future<Either<Failure, void>> sendQuestions({
    required List<QuestionCategory> categories,
    required SchoolItem item,
    required String teacherId,
  });

  Future<Either<Failure, List<SchoolItem>>> getSchoolItems();

  Future<Either<Failure, List<ChildMenuModel>>> getMenus({required DateTime? dateTime, required int? childId});

  Future<Either<Failure, List<String>>> uploadAttachments(List<String> filePathes);
}
