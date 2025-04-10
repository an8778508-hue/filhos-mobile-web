import 'package:escola/core/components/loading/loading.dart';
import 'package:escola/core/components/loading/loading_overlay.dart';
import 'package:escola/core/components/widgets/app_bar.dart';
import 'package:escola/core/components/widgets/error_widget.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/features/diary/models/school_item.dart';
import 'package:escola/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:escola/features/diary/presentation/widgets/professor_questions/templates_list.dart';
import 'package:escola/features/diary/presentation/widgets/professor_questions/update_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfessorQuestions extends StatelessWidget {
  final SchoolItem item;
  final bool filterAttendance;
  final bool filterMedia;

  const ProfessorQuestions({
    super.key,
    required this.item,
    this.filterAttendance = false,
    this.filterMedia = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di<DiaryBloc>()
        ..add(GetQuestionTemplates(
          filterAttendance: filterAttendance,
          filterMedia: filterMedia,
        )),
      child: Scaffold(
        backgroundColor: context.colors.secondaryScaffold,
        appBar: MyAppBar(
          title: LocalizationKeys.diary.tr(context),
          hasNotification: true,
        ),
        body: BlocBuilder<DiaryBloc, DiaryState>(
          builder: (context, state) {
            final templates = context.watch<DiaryBloc>().questionstemplates;
            return Stack(
              children: [
                Column(
                  children: [
                    if (state is QuestionsTemplatesLoading) ...[
                      const Expanded(child: Center(child: Loading()))
                    ] else if (templates != null) ...[
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              TemplatesList(item: item, categories: templates),
                              SizedBox(height: 15.h),
                              UpdateQuestionsButton(item: item),
                              SizedBox(height: 30.h),
                            ],
                          ),
                        ),
                      ),
                    ] else if (state is QuestionsTemplatesError) ...[
                      Expanded(
                        child: Center(
                          child: ErrorScreen(
                            errorText: state.failure.message,
                            onRetry: () {
                              context.read<DiaryBloc>().add(GetQuestionTemplates());
                            },
                          ),
                        ),
                      )
                    ]
                  ],
                ),
                BlocSelector<DiaryBloc, DiaryState, bool>(
                  selector: (state) => state is SendQuestionsLoading,
                  builder: (context, loading) => loading
                      ? const LoadingOverlay()
                      : const SizedBox(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
