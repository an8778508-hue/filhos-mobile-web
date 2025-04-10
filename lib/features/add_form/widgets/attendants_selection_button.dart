import 'package:escola/core/components/fields/error_field.dart';
import 'package:escola/core/components/fields/search_field.dart';
import 'package:escola/core/components/widgets/error_widget.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/diary/models/school_item.dart';
import 'package:escola/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:escola/features/diary/presentation/widgets/professor_questions/school_items_list.dart';
import 'package:escola/features/search/bloc/search_bloc.dart';
import 'package:escola/features/settings/events/event_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:escola/core/components/loading/loading.dart';

class AttendantsSelectionButton extends StatefulWidget {
  const AttendantsSelectionButton({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final ValueNotifier<List<SchoolItem>> controller;

  @override
  State<AttendantsSelectionButton> createState() => _AttendantsSelectionButtonState();
}

class _AttendantsSelectionButtonState extends State<AttendantsSelectionButton> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
            side: BorderSide(
              color: context.colors.primary,
              width: 2.w,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10.r),
            onTap: () async {
              final result = await AttendantsSelectionSheet.open(context, initial: [...widget.controller.value]);
              if (validList(result)) {
                widget.controller.value = [...result!];
              }
            },
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: 18.h,
                horizontal: 18.w,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outlined,
                    size: 20.sp,
                    color: context.colors.secondary,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    LocalizationKeys.add_now.tr(context),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: context.colors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ValueListenableBuilder(
          valueListenable: widget.controller,
          builder: (context, value, child) => Padding(
            padding: EdgeInsets.only(top: 10.h),
            child: Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.start,
              runAlignment: WrapAlignment.start,
              spacing: 8,
              runSpacing: 0,
              children: [
                ...value
                    .map(
                      (item) => FilterTag(
                        tag: item.name ?? '',
                        onRemove: () {
                          widget.controller.value.removeWhere((e) => e.id == item.id && e.type == item.type);
                          widget.controller.value = [...widget.controller.value];
                        },
                      ),
                    )
                    .toList(),
              ],
            ),
          ),
        ),
        FormField(
          validator: (value) {
            if (validList(widget.controller.value)) {
              return null;
            }
            return LocalizationKeys.this_field_cant_be_empty.tr(context);
          },
          builder: (field) => field.hasError && validString(field.errorText)
              ? ErrorField(
                  text: field.errorText!,
                )
              : const SizedBox(),
        ),
      ],
    );
  }
}

class AttendantsSelectionSheet extends StatefulWidget {
  const AttendantsSelectionSheet({super.key, required this.initial});

  final List<SchoolItem> initial;

  static Future<List<SchoolItem>?> open(BuildContext context, {List<SchoolItem> initial = const []}) =>
      showModalBottomSheet<List<SchoolItem>>(
        context: context,
        backgroundColor: context.colors.background,
        isScrollControlled: true,
        clipBehavior: Clip.antiAlias,
        enableDrag: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 1,
        ),
        useSafeArea: true,
        builder: (context) => AttendantsSelectionSheet(initial: initial),
      );

  @override
  State<AttendantsSelectionSheet> createState() => _AttendantsSelectionSheetState();
}

class _AttendantsSelectionSheetState extends State<AttendantsSelectionSheet> {
  final TextEditingController _searchController = TextEditingController();
  late final ValueNotifier<List<SchoolItem>> selectedController;

  @override
  void initState() {
    super.initState();
    selectedController = ValueNotifier<List<SchoolItem>>([...widget.initial]);
  }

  @override
  dispose() {
    _searchController.dispose();
    selectedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop([...selectedController.value]),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0.w),
              child: Text(
                LocalizationKeys.save.tr(context),
                style: TextStyle(
                  color: context.colors.secondaryTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20.sp,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: MultiBlocProvider(
          providers: [
            BlocProvider<DiaryBloc>(create: (context) => di<DiaryBloc>()..add(GetSchoolItems())),
            BlocProvider<SearchBloc>(create: (context) => di<SearchBloc>()),
          ],
          child: Builder(
            builder: (context) {
              return BlocBuilder<SearchBloc, SearchState>(
                builder: (context, searchState) {
                  return BlocBuilder<DiaryBloc, DiaryState>(
                    builder: (context, diaryState) {
                      final items = context.read<DiaryBloc>().diaryItems;
                      final searchItems = context.read<SearchBloc>().schoolItemsResult;

                      return Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w).add(EdgeInsets.only(bottom: 20.h)),
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
                                  if (diaryState is SchoolItemsLoading ||
                                      searchState is SearchLoading ||
                                      diaryState is DiaryInitial) ...[
                                    const Expanded(child: Center(child: Loading()))
                                  ] else if (searchItems != null) ...[
                                    if (searchItems.isEmpty) ...[
                                      const EmptySearchResult()
                                    ] else ...[
                                      ValueListenableBuilder(
                                        valueListenable: selectedController,
                                        builder: (context, value, child) => SchoolItemsList(
                                          items: searchItems,
                                          showAll: true,
                                          showAllChildren: false,
                                          showAllTeachers: true,
                                          selectedItems: [...value],
                                          onSchoolItemsPressed: onItemSelected,
                                        ),
                                      ),
                                    ],
                                  ] else if (items != null) ...[
                                    ValueListenableBuilder(
                                      valueListenable: selectedController,
                                      builder: (context, value, child) => SchoolItemsList(
                                        items: items,
                                        showAll: true,
                                        showAllChildren: false,
                                        showAllTeachers: true,
                                        selectedItems: [...value],
                                        onSchoolItemsPressed: onItemSelected,
                                      ),
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
                                    ),
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
                                    ),
                                  ],
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
            },
          ),
        ),
      ),
    );
  }

  onItemSelected(SchoolItem item) {
    bool find(SchoolItem e) => e.id == item.id && e.type == item.type;
    if (selectedController.value.any(find)) {
      selectedController.value.removeWhere(find);
    } else {
      switch (item.type) {
        case SchoolItemType.all:
          selectedController.value.clear();
          selectedController.value.add(item);
          break;
        case SchoolItemType.allChildType:
          selectedController.value.removeWhere((e) => e.type == SchoolItemType.all);
          selectedController.value.removeWhere((e) =>
              e.type == SchoolItemType.level ||
              e.type == SchoolItemType.classType ||
              e.type == SchoolItemType.childType ||
              e.type == SchoolItemType.parentType);
          selectedController.value.add(item);
          break;
        case SchoolItemType.allTeachersType:
          selectedController.value.removeWhere((e) => e.type == SchoolItemType.all);
          selectedController.value.removeWhere((e) => e.type == SchoolItemType.allTeachersType);
          selectedController.value.removeWhere((e) => e.type == SchoolItemType.teacherType);
          selectedController.value.add(item);
          break;
        case SchoolItemType.level:
        case SchoolItemType.classType:
        case SchoolItemType.childType:
        case SchoolItemType.parentType:
          selectedController.value.removeWhere((e) => e.type == SchoolItemType.all);
          selectedController.value.removeWhere((e) => e.type == SchoolItemType.allChildType);
          selectedController.value.add(item);
          break;
        case SchoolItemType.teacherType:
          selectedController.value.removeWhere((e) => e.type == SchoolItemType.all);
          selectedController.value.removeWhere((e) => e.type == SchoolItemType.allTeachersType);
          selectedController.value.add(item);
          break;
      }
    }
    selectedController.value = [...selectedController.value];
  }
}
