import 'package:escola/core/components/fields/search_field.dart';
import 'package:escola/core/components/loading/loading.dart';
import 'package:escola/core/components/sheets/child_details_sheet.dart';
import 'package:escola/core/components/widgets/app_bar.dart';
import 'package:escola/core/components/widgets/error_widget.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/models/child_details_model.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/all_children/presentation/bloc/all_children_bloc.dart';
import 'package:escola/features/diary/models/school_item.dart';
import 'package:escola/features/diary/presentation/widgets/professor_questions/school_items_list.dart';
import 'package:escola/features/search/bloc/search_bloc.dart';
import 'package:escola/flavors/app_flavors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AllChildrenScreen extends StatefulWidget {
  const AllChildrenScreen({
    super.key,
  });

  @override
  State<AllChildrenScreen> createState() => _AllChildrenScreenState();
}

class _AllChildrenScreenState extends State<AllChildrenScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: MyAppBar(
        title: LocalizationKeys.all_children.tr(context),
        hasNotification: true,
        hasAvatar: false,
      ),
      body: SafeArea(
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AllChildrenBloc>(create: (context) => di<AllChildrenBloc>()..add(GetAllChildren())),
            BlocProvider<SearchBloc>(create: (context) => di<SearchBloc>()),
          ],
          child: Builder(builder: (context) {
            return BlocBuilder<SearchBloc, SearchState>(
              builder: (context, searchState) {
                return BlocBuilder<AllChildrenBloc, AllChildrenState>(
                  builder: (context, allChildrenState) {
                    final items = context.read<AllChildrenBloc>().allChildren;

                    final childrenSearchResult = context.read<SearchBloc>().globalSearchResult?.children;
                    final parentsSearchResult = context.read<SearchBloc>().globalSearchResult?.parents;

                    List<SchoolItem>? searchItems = [
                      ...childrenSearchResult ?? [],
                      ...parentsSearchResult ?? [],
                    ];
                    if (childrenSearchResult == null && parentsSearchResult == null) {
                      searchItems = null;
                    }

                    return Column(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 18.w).copyWith(bottom: 20.w, top: 10.w),
                          decoration: BoxDecoration(
                            color: context.colors.primary,
                          ),
                          child: SearchField(
                            hint: LocalizationKeys.search_by_child_name.tr(context),
                            showClearButton: searchItems != null,
                            onClearSearch: () => context.read<SearchBloc>().add(ClearSearch()),
                            onSearch: (value) {
                              if (stringNotNullOrEmpty(value)) {
                                context.read<SearchBloc>().add(GlobalSearch(query: value,isTeacher: context.isProfessors  ));
                              }
                            },
                            controller: _searchController,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            color: Colors.white,
                            child: Column(
                              children: [
                                if (searchState is SearchLoading || allChildrenState is AllChildrenLoading) ...[
                                  const Expanded(child: Center(child: Loading()))
                                ] else if (searchItems != null) ...[
                                  if (searchItems.isEmpty) ...[
                                    Padding(
                                      padding: EdgeInsets.all(20.0.h),
                                      child: const EmptySearchResult(),
                                    )
                                  ] else ...[
                                    SchoolItemsList(
                                        items: searchItems,
                                        showAllChildren: false && !validList(items),
                                        textColor: Colors.black,
                                        onSchoolItemsPressed: (item) => ChildDetailsSheet.openSheet(
                                            context: context, childDetailsModel: getDetailsFromSchoolItem(item)))
                                  ]
                                ] else if (items != null) ...[
                                  SchoolItemsList(
                                      items: items,
                                      showAllChildren: false,
                                      textColor: Colors.black,
                                      onSchoolItemsPressed: (item) => ChildDetailsSheet.openSheet(
                                          context: context, childDetailsModel: getDetailsFromSchoolItem(item)))
                                ] else if (searchState is SearchFailed) ...[
                                  Expanded(
                                    child: Center(
                                      child: ErrorScreen(
                                        errorText: searchState.failure.message,
                                        onRetry: () {
                                          context.read<SearchBloc>().add(GlobalSearch(query: _searchController.text,isTeacher: context.isProfessors  ));
                                        },
                                      ),
                                    ),
                                  )
                                ]
                              ],
                            ),
                          ),
                        )
                      ],
                    );
                  },
                );
              },
            );
          }),
        ),
      ),
    );
  }

  ChildDetailsModel getDetailsFromSchoolItem(SchoolItem item) {
    return ChildDetailsModel(
        id: item.id,
        name: item.name,
        code: item.id.toString(),
        age: item.id.toString(),
        gender: null,
        grade: item.classRoom,
        birthday: null,
        avatar: item.avatar,
        series: null,
        responsible: item.parent,
        enroll_parent: item.parent);
  }
}
