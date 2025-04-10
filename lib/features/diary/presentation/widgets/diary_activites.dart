import 'package:escola/core/components/empty/empty_widget.dart';
import 'package:escola/core/components/my_icon.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/diary/models/question_category.dart';
import 'package:escola/features/diary/presentation/widgets/menu_button.dart';
import 'package:escola/features/diary/presentation/widgets/professor_widget.dart';
import 'package:escola/features/diary/presentation/widgets/question_category_widget.dart';
import 'package:escola/shared/assets/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/widgets_ext.dart';
import 'package:escola/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:escola/features/diary/presentation/widgets/child_header.dart';

class DiaryActivities extends StatelessWidget {
  final bool hasChild;
  const DiaryActivities({super.key, required this.hasChild});

  @override
  Widget build(BuildContext context) {
    final diaryActivites = context.watch<DiaryBloc>().activities;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.secondaryScaffold,
        borderRadius: BorderRadius.circular(15.r),
      ),
      margin: EdgeInsets.symmetric(horizontal: 20.h, vertical: 20.h),
      child: diaryActivites.isEmpty
          ? Column(
              children: [
                SizedBox(
                  height: 100.h,
                ),
                Center(
                  child: EmptyWidget(
                      title: LocalizationKeys.no_activities.tr(context), icon: Assets.icons.inactiveDairy.path),
                ),
              ],
            )
          : ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: diaryActivites.length,
              itemBuilder: (context, index) {
                final activity = diaryActivites[index];
                print('DiaryActivities.build ${diaryActivites}');
                final questionCategories = activity.questionCategories;

                return Container(
                  color: Colors.white,
                  margin: EdgeInsets.only(bottom: 20.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (activity.childModel != null && !hasChild) ...[
                          Column(
                            children: [
                              ChildHeader(child: activity.childModel!, activity: activity),
                              SizedBox(height: 10.h),
                              Container(
                                color: context.colors.secondaryScaffold,
                                height: 1.h,
                              ),
                            ],
                          ),
                      ],
                      Text(
                        LocalizationKeys.the_latest_activities.tr(context),
                        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w500, color: Colors.black),
                      ).addPadding(
                          padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 20).copyWith(bottom: 20.h)),
                      if(activity.mainCategory != null)
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                                bottom: BorderSide(color: context.colors.scaffold, width: 1.w),
                                top: BorderSide(color: context.colors.scaffold, width: 1.w)),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  if (stringNotNullOrEmpty(activity.mainCategory!.image)) ...[
                                    MyIcon(
                                      activity.mainCategory!.image ?? "",
                                      size: 25.w,
                                      // color: context.colors.primary,
                                    ),
                                    SizedBox(width: 10.w),
                                  ],
                                  Text(
                                    activity.mainCategory!.name ?? "",
                                    style: TextStyle(
                                      fontSize: 22.sp,
                                      fontWeight: FontWeight.w600,
                                      color: context.colors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              if (activity.mainCategory!.type == QuestionCategory.foodType) ...[
                                MenuButton(date: activity.date ?? DateTime.now(), childId: activity.childModel?.id)
                              ]
                            ],
                          ),
                        ),
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: questionCategories.length,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final category = questionCategories[index];
                          return QuestionCategoryWidget(category: category, activity: activity);
                        },
                      ),
                      Container(
                        color: context.colors.secondaryScaffold,
                        height: 1.h,
                      ),
                      if (activity.professor != null) ...[
                        ProfessorWidget(activity: activity),
                      ]
                    ],
                  ),
                );
              },
            ),
    );
  }
}
