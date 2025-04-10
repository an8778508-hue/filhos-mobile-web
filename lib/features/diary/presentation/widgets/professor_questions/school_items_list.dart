import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/features/diary/models/school_item.dart';
import 'package:escola/features/diary/presentation/widgets/professor_questions/school_list_item.dart';
import 'package:flutter/material.dart';

class SchoolItemsList extends StatelessWidget {
  final List<SchoolItem> items;
  final List<SchoolItem>? selectedItems;
  final Function(SchoolItem) onSchoolItemsPressed;
  final bool showAllChildren;
  final bool showAll;
  final bool showAllTeachers;
  final Color? textColor;
  final double? titleSize, subTitleSize;

  const SchoolItemsList(
      {super.key,
      required this.items,
      required this.onSchoolItemsPressed,
      this.selectedItems,
      this.showAllChildren = false,
      this.showAll = false,
      this.showAllTeachers = false,
      this.textColor,
      this.titleSize,
      this.subTitleSize});

  @override
  Widget build(BuildContext context) {
    final allChildrenItem = SchoolItem(
        name: LocalizationKeys.all_children.tr(context),
        id: 0,
        classRoom: null,
        avatar: null,
        type: SchoolItemType.allChildType);
    final allTeachersItem = SchoolItem(
        name: LocalizationKeys.all_teachers.tr(context),
        id: 0,
        classRoom: null,
        avatar: null,
        type: SchoolItemType.allTeachersType);
    final allItem = SchoolItem(
        name: LocalizationKeys.all.tr(context),
        id: 0,
        classRoom: null,
        avatar: null,
        type: SchoolItemType.all);

    return Expanded(
      child: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (showAll) ...[
                GestureDetector(
                  onTap: () {
                    onSchoolItemsPressed(allItem);
                  },
                  child: SchoolListItem(
                    item: allItem,
                    hasBorder: true,
                    textColor: textColor,
                    selected: selectedItems?.any((e) => e.type == SchoolItemType.all),
                    hasArrow: selectedItems == null,
                  ),
                )
              ],
              if (showAllChildren) ...[
                GestureDetector(
                  onTap: () {
                    onSchoolItemsPressed(allChildrenItem);
                  },
                  child: SchoolListItem(
                    item: allChildrenItem,
                    hasBorder: true,
                    textColor: textColor,
                    selected: selectedItems?.any((e) => e.type == SchoolItemType.allChildType),
                    hasArrow: selectedItems == null,
                  ),
                )
              ],
              if (showAllTeachers) ...[
                GestureDetector(
                  onTap: () {
                    onSchoolItemsPressed(allTeachersItem);
                  },
                  child: SchoolListItem(
                    item: allTeachersItem,
                    hasBorder: true,
                    textColor: textColor,
                    selected: selectedItems?.any((e) => e.type == SchoolItemType.allTeachersType),
                    hasArrow: selectedItems == null,
                  ),
                )
              ],
              ListView.builder(
                  itemCount: items.length,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final isLast = index == items.length - 1;
                    final item = items[index];
                    final isSelected = selectedItems
                        ?.any((e) => e.id == item.id && e.type == item.type);
                    return GestureDetector(
                      onTap: () {
                        onSchoolItemsPressed(item);
                      },
                      child: SchoolListItem(
                        item: item,
                        titleSize: titleSize,
                        subTitleSize: subTitleSize,
                        hasBorder: !isLast,
                        selected: isSelected,
                        hasArrow: selectedItems == null,
                        textColor: textColor,
                      ),
                    );
                  }),
            ],
          ),
        ),
      ),
    );
  }
}
