import 'package:escola/core/components/fields/search_field.dart';
import 'package:escola/core/components/widgets/error_widget.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/funuctions/widget_functions.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/diary/presentation/widgets/professor_questions/school_items_list.dart';
import 'package:escola/features/diary/presentation/widgets/professor_questions/professor_questions.dart';
import 'package:escola/features/search/bloc/search_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:escola/core/components/loading/loading.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
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
      body: SafeArea(
        child: BlocProvider<SearchBloc>(
          create: (context) => di<SearchBloc>(),
          child: Builder(builder: (context) {
            return BlocBuilder<SearchBloc, SearchState>(
                builder: (context, state) {
              final items = context.read<SearchBloc>().schoolItemsResult;

              return Column(
                children: [
                  Container(
                    padding: EdgeInsets.only(bottom: 10.w, top: 10.w),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                            bottom: BorderSide(
                                color: context.colors.secondaryScaffold,
                                width: 2.w))),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 30.w, vertical: 10.h),
                            child: Icon(
                              Icons.arrow_back_ios_rounded,
                              color: Colors.black,
                              size: 22.w,
                            ),
                          ),
                        ),
                        Expanded(
                          child: SearchField(
                            backgroundColor: const Color(0xffeceef1),
                            hint: LocalizationKeys.search_by_child_name
                                .tr(context),
                            showClearButton: items != null,
                            onClearSearch: () =>
                                context.read<SearchBloc>().add(ClearSearch()),
                            onSearch: (value) {
                              if (stringNotNullOrEmpty(value)) {
                                context
                                    .read<SearchBloc>()
                                    .add(ChildSearch(query: value));
                              }
                            },
                            controller: _searchController,
                          ),
                        ),
                        SizedBox(width: 20.w),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          if (state is SearchLoading) ...[
                            const Expanded(child: Center(child: Loading()))
                          ] else if (items != null) ...[
                            if (items.isEmpty) ...[
                              Container(
                                  margin: EdgeInsets.only(top: 50.h),
                                  child: const EmptySearchResult())
                            ] else ...[
                              SchoolItemsList(
                                items: items,
                                showAllChildren: false && !validList(items),
                                onSchoolItemsPressed: (item) {
                                  WidgetFunctions.navigateTo(
                                      context, ProfessorQuestions(item: item));
                                },
                              )
                            ]
                          ] else if (state is SearchFailed) ...[
                            Expanded(
                              child: Center(
                                child: ErrorScreen(
                                  errorText: state.failure.message,
                                  onRetry: () {
                                    context.read<SearchBloc>().add(ChildSearch(
                                        query: _searchController.text));
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
          }),
        ),
      ),
    );
  }
}
