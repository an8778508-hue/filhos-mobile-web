import 'package:escola/core/utils/funuctions/widget_functions.dart';
import 'package:escola/features/diary/models/child_model.dart';
import 'package:escola/features/diary/presentation/parents_diary_screen.dart';
import 'package:escola/features/diary/presentation/school_items_screen.dart';
import 'package:escola/features/diary/presentation/widgets/professor_questions/professor_questions.dart';
import 'package:escola/flavors/app_flavors.dart';
import 'package:flutter/material.dart';

class DiaryScreen extends StatelessWidget {
  final ChildModel? child;
  final bool filterAttendance;
  final bool filterMedia;

  const DiaryScreen({
    super.key,
    this.child,
    this.filterAttendance = false,
    this.filterMedia = false,
  });

  @override
  Widget build(BuildContext context) {
    return context.isProfessors
        ? SchoolItemsScreen(
            onItemPressed: (item) => WidgetFunctions.navigateTo(
                context,
                ProfessorQuestions(
                  item: item,
                  filterAttendance: filterAttendance,
                  filterMedia: filterMedia,
                )),
          )
        : ParentDiaryScreen(child: child);
  }
}
