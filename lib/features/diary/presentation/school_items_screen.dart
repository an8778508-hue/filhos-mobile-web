import 'package:escola/core/components/fields/search_field.dart';
import 'package:escola/core/components/widgets/app_bar.dart';
import 'package:escola/core/components/widgets/error_widget.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/diary/models/school_item.dart';
import 'package:escola/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:escola/features/diary/presentation/widgets/professor_questions/school_items_list.dart';
import 'package:escola/features/search/bloc/search_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:escola/core/components/loading/loading.dart';

class SchoolItemsScreen extends StatefulWidget {
  final String? title;
  final bool hasAppBar;
  final Function(SchoolItem) onItemPressed;
  const SchoolItemsScreen({super.key, required this.onItemPressed, this.title, this.hasAppBar = true});

  @override
  State<SchoolItemsScreen> createState() => _SchoolItemsScreenState();
}

class _SchoolItemsScreenState extends State<SchoolItemsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.primary,
      appBar: widget.hasAppBar
          ? MyAppBar(
              title: widget.title ?? LocalizationKeys.diary.tr(context),
              hasNotification: true,
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<DiaryBloc>(create: (context) => di<DiaryBloc>()..add(GetSchoolItems())),
            BlocProvider<SearchBloc>(create: (context) => di<SearchBloc>()),
          ],
          child: Builder(builder: (context) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<DiaryBloc>().add(GetSchoolItems());
              },
              child: BlocBuilder<SearchBloc, SearchState>(
                builder: (context, searchState) {
                  return BlocBuilder<DiaryBloc, DiaryState>(builder: (context, diaryState) {
                    final items = context.read<DiaryBloc>().diaryItems;
                    final searchItems = context.read<SearchBloc>().schoolItemsResult;

                    return Column(
                      children: [
                        Container(
                          color: context.colors.primary,
                          padding: EdgeInsets.symmetric(horizontal: 18.w).copyWith(bottom: 20.w, top: 10.w),
                          child: SearchField(
                            hint: LocalizationKeys.search_by_child_name.tr(context),
                            showClearButton: searchItems != null,
                            onClearSearch: () => context.read<SearchBloc>().add(ClearSearch()),
                            onSearch: (value) {
                              if (stringNotNullOrEmpty(value)) {
                                context.read<SearchBloc>().add(ChildSearch(query: value));
                              }
                            },
                            controller: _searchController,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            color: context.colors.secondaryScaffold,
                            child: Column(
                              children: [
                                SizedBox(height: 20.h),
                                if (diaryState is SchoolItemsLoading ||
                                    searchState is SearchLoading ||
                                    diaryState is DiaryInitial) ...[
                                  const Expanded(child: Center(child: Loading()))
                                ] else if (searchItems != null) ...[
                                  if (searchItems.isEmpty) ...[
                                    const EmptySearchResult()
                                  ] else ...[
                                    SchoolItemsList(
                                      items: searchItems,
                                      textColor: context.colors.primary,
                                      showAllChildren:false&& !validList(searchItems),
                                      onSchoolItemsPressed: (item) {
                                        widget.onItemPressed(item);
                                      },
                                    )
                                  ]
                                ] else if (items != null) ...[
                                  SchoolItemsList(
                                    items: items,
                                    showAllChildren: false,
                                    textColor: context.colors.primary,
                                    onSchoolItemsPressed: (item) {
                                      widget.onItemPressed(item);
                                    },
                                  )
                                ] else if (diaryState is SchoolItemsError) ...[
                                  Expanded(
                                    child: Center(
                                      child: ErrorScreen(
                                        errorText: diaryState.failure.message,
                                        onRetry: () {
                                          context.read<DiaryBloc>().add(GetSchoolItems());
                                        },
                                      ),
                                    ),
                                  )
                                ] else if (searchState is SearchFailed) ...[
                                  Expanded(
                                    child: Center(
                                      child: ErrorScreen(
                                        errorText: searchState.failure.message,
                                        onRetry: () {
                                          context.read<SearchBloc>().add(ChildSearch(query: _searchController.text));
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
                  });
                },
              ),
            );
          }),
        ),
      ),
    );
  }
}
