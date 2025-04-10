import 'package:escola/core/components/buttons/custom_button.dart';
import 'package:escola/core/components/fields/custom_text_field.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/features/diary/models/school_item.dart';
import 'package:escola/features/diary/models/school_item.dart';
import 'package:escola/features/search_for_filter/model/search_for_filter_model.dart';
import 'package:escola/features/search_for_filter/search_for_filter_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FilterSheet extends StatefulWidget {
  const FilterSheet({
    super.key, required this.filterModel,
  });
  final FilterModel filterModel;

  static Future openSheet(BuildContext context,FilterModel filterModel) async {
    return await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      backgroundColor: context.colors.background,
      builder: (context) => FilterSheet(filterModel: filterModel),
    );
  }

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late final TextEditingController theTeacherController ;
  late final TextEditingController studentsParentsController ;
  late final TextEditingController levelsController ;
  late final ValueNotifier<SchoolItem?> teacher;
  late final ValueNotifier<SchoolItem?> parentOrChild;
  late final ValueNotifier<SchoolItem?> levels;

  @override
  void initState() {

    super.initState();
    init();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.background,
      height: 810.csh,
      padding: EdgeInsets.symmetric(vertical: 30.csh, horizontal: 18.csw),
      child: Column(
        children: [
          SizedBox(
            width: double.maxFinite,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  LocalizationKeys.filter.tr(context),
                  style: TextStyle(
                    color: context.colors.primary,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Icon(
                    Icons.close,
                    color: context.colors.greyDarker,
                    size: 20.sp,
                  ),
                )
              ],
            ),
          ),
          SizedBox(
            height: 30.csh,
          ),
          ValueListenableBuilder(
            valueListenable: teacher,
            builder: (context, value, child) => CustomTextField(
              onTap: () async {
                final model = await Navigator.push(
                    context, MaterialPageRoute(builder: (_) => SearchForFilterScreen(searchModelType: SearchForFilterModelType.teacher)));
                if(model != null) {
                  teacher.value =model;
                  theTeacherController.text = teacher.value?.name??'';
                }
              },
              readOnly: true,
              hint: LocalizationKeys.the_teacher.tr(context),
              hintFontSize: 18.sp,
              controller: theTeacherController,
              backgroundColor: context.colors.scaffold,
              trailing: GestureDetector(
                onTap: () {
                  if (value != null) {
                    teacher.value =null;
                    theTeacherController.clear();
                  }
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  child: Icon(
                    value !=null ? Icons.clear : Icons.keyboard_arrow_right_sharp,
                    color: Colors.black,
                    size: 24.w,
                  ),
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20.csw, vertical: 0.csh),
              hintColor: context.colors.greyDarker,
              borderRadius: 12.r,
            ),
          ),
          SizedBox(
            height: 16.csh,
          ),
          ValueListenableBuilder(
            valueListenable: parentOrChild,
            builder: (context, value, child) => CustomTextField(
              onTap: () async{
                final model = await Navigator.push(
                    context, MaterialPageRoute(builder: (_) => SearchForFilterScreen(searchModelType: SearchForFilterModelType.childOrParent)));
                if(model != null) {
                  parentOrChild.value =model;
                  studentsParentsController.text = parentOrChild.value?.name??'';
                }
              },
              readOnly: true,
              hint: LocalizationKeys.students_parents.tr(context),
              hintFontSize: 18.sp,
              trailing: GestureDetector(
                onTap: () {
                  if (value != null) {
                    parentOrChild.value =null;
                    studentsParentsController.clear();
                  }
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  child: Icon(
                    value !=null ? Icons.clear : Icons.keyboard_arrow_right_sharp,
                    color: Colors.black,
                    size: 24.w,
                  ),
                ),
              ),
              controller: studentsParentsController,
              backgroundColor: context.colors.scaffold,
              padding: EdgeInsets.symmetric(horizontal: 20.csw, vertical: 0.csh),
              hintColor: context.colors.greyDarker,
              borderRadius: 12.r,
            ),
          ),
          SizedBox(
            height: 16.csh,
          ),
          ValueListenableBuilder(
            valueListenable: levels,
            builder: (context, value, child) => CustomTextField(
              onTap: () async{
                final model = await Navigator.push(
                    context, MaterialPageRoute(builder: (_) => SearchForFilterScreen(searchModelType: SearchForFilterModelType.level)));
                if(model != null) {
                  levels.value =model;
                  levelsController.text = levels.value?.name??'';
                }
              },
              readOnly: true,
              hint: LocalizationKeys.levels.tr(context),
              trailing: GestureDetector(
                onTap: () {
                  if (value != null) {
                    levels.value =null;
                    levelsController.clear();
                  }
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  child: Icon(
                    value !=null ? Icons.clear : Icons.keyboard_arrow_right_sharp,
                    color: Colors.black,
                    size: 24.w,
                  ),
                ),
              ),
              hintFontSize: 18.sp,
              controller: levelsController,
              backgroundColor: context.colors.scaffold,
              padding: EdgeInsets.symmetric(horizontal: 20.csw, vertical: 0.csh),
              hintColor: context.colors.greyDarker,
              borderRadius: 12.r,
            ),
          ),
          SizedBox(
            height: 30.csh,
          ),
          CustomButton(
            title: LocalizationKeys.save.tr(context),
            onTap: () {
              final model = FilterModel(
                teacher: teacher.value,
                parentOrChild: parentOrChild.value,
                levels: levels.value,
              );
              Navigator.of(context).pop(model);
            },
            horizontalPadding: 0,
            textVerticalPadding: 20,
          )
        ],
      ),
    );
  }

  void init() {
    teacher = ValueNotifier(widget.filterModel.teacher);
    parentOrChild = ValueNotifier(widget.filterModel.parentOrChild);
    levels = ValueNotifier(widget.filterModel.levels);

    theTeacherController = TextEditingController(text: widget.filterModel.teacher?.name??'');
    studentsParentsController = TextEditingController(text: widget.filterModel.parentOrChild?.name??'');
    levelsController = TextEditingController(text: widget.filterModel.levels?.name??'');
  }
}

class FilterModel {
  final SchoolItem? teacher;

  final SchoolItem? parentOrChild;

  final SchoolItem? levels;

  copyWith({SchoolItem? teacher, SchoolItem? parentOrChild, SchoolItem? levels}){
    return FilterModel(
      teacher: levels??this.teacher,
      parentOrChild: levels??this.parentOrChild,
      levels: levels??this.levels,
    );
  }
  removeTeacher(){
    return FilterModel(
      parentOrChild: parentOrChild,
      levels: levels,
    );
  }
  removeParent(){
    return FilterModel(
      teacher: teacher,
      levels: levels,
    );
  }
  removeLevel(){
    return FilterModel(
      teacher: teacher,
      parentOrChild: parentOrChild,
    );
  }


  FilterModel({this.teacher, this.parentOrChild, this.levels});
}