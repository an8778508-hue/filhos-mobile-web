import 'package:escola/core/components/fields/search_field.dart';
import 'package:escola/core/components/loading/loading.dart';
import 'package:escola/core/components/widgets/app_bar.dart';
import 'package:escola/core/components/widgets/error_widget.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/diary/models/school_item.dart';
import 'package:escola/features/search/models/global_search.dart';
import 'package:escola/features/search_for_filter/bloc/search_for_filter_bloc.dart';
import 'package:escola/features/search_for_filter/bloc/search_for_filter_event.dart';
import 'package:escola/features/search_for_filter/bloc/search_for_filter_state.dart';
import 'package:escola/features/search_for_filter/model/search_for_filter_model.dart';
import 'package:escola/features/search_for_filter/widgets/search_for_filter_items_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SearchForFilterScreen extends StatefulWidget {
  const SearchForFilterScreen({super.key, required this.searchModelType, this.hasInitial = false});

  final SearchForFilterModelType searchModelType;
  final bool hasInitial;

  @override
  State<SearchForFilterScreen> createState() => _SearchForFilterScreenState();
}

class _SearchForFilterScreenState extends State<SearchForFilterScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.scaffold,
      appBar: MyAppBar(
        title: LocalizationKeys.search.tr(context),
        hasNotification: true,
      ),
      body: BlocProvider<SearchForFilterBloc>(
        create: (context) {
          if (widget.hasInitial) {
            return di<SearchForFilterBloc>() ..add(GetSearchForFilterItems(widget.searchModelType));
          }
            return di<SearchForFilterBloc>();
        },
        child: Builder(
          builder: (context) {
            return BlocBuilder<SearchForFilterBloc, SearchForFilterState>(
              builder: (context, state) {
                final items = context.read<SearchForFilterBloc>().diaryItems;
                List<SchoolItem> searchItems = getSearchItems(context.read<SearchForFilterBloc>().searchForFilterItems);

                return Column(
                  children: [
                    Container(
                      color: context.colors.primary,
                      padding: EdgeInsets.symmetric(horizontal: 18.w).copyWith(bottom: 20.w, top: 10.w),
                      child: SearchField(
                        hint: LocalizationKeys.search.tr(context),
                        showClearButton: validList(searchItems),
                        onClearSearch: () {
                          context.read<SearchForFilterBloc>().add(ClearSearchForFilter());
                        },
                        onSearch: (value) {
                          if (stringNotNullOrEmpty(value)) {
                            context
                                .read<SearchForFilterBloc>()
                                .add(SubmitSearchForFilter(query: value, searchModelType: widget.searchModelType));
                          }
                        },
                        controller: _searchController,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: context.colors.scaffold,
                        child: Column(
                          children: [
                            if (state is SearchForFilterItemsLoading) ...[
                              const Expanded(child: Center(child: Loading()))
                            ] else if (searchItems != null) ...[
                              if (searchItems.isEmpty) ...[
                                const EmptySearchResult()
                              ] else ...[
                                SearchForFilterItemsList(
                                  items: searchItems,
                                  searchModelType: widget.searchModelType,
                                  onSearchForFilterItemsPressed: (SchoolItem searchModel) {
                                    Navigator.of(context).pop(searchModel);
                                  },
                                )
                              ]
                            ] else if (items != null) ...[
                              SearchForFilterItemsList(
                                items: items,
                                searchModelType: widget.searchModelType,
                                onSearchForFilterItemsPressed: (SchoolItem searchModel) {
                                  Navigator.of(context).pop(searchModel);
                                },
                              )
                            ] else if (state is SearchForFilterItemsError) ...[
                              Expanded(
                                child: Center(
                                  child: ErrorScreen(
                                    errorText: state.failure.message,
                                    onRetry: () {
                                      context.read<SearchForFilterBloc>().add(GetSearchForFilterItems(widget.searchModelType));
                                    },
                                  ),
                                ),
                              )
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  List<SchoolItem> getSearchItems(GlobalSearchResult? searchForFilterItems) {
    if(searchForFilterItems == null) {
      return [];
    }

    switch (widget.searchModelType){
      case SearchForFilterModelType.childOrParent:
        return [...searchForFilterItems.parents,...searchForFilterItems.children,];
      case SearchForFilterModelType.classType:
        return [] ;
      case SearchForFilterModelType.teacher:
        return [...searchForFilterItems.teachers];
      case SearchForFilterModelType.level:
        return [...searchForFilterItems.levels];
    }
  }
}
