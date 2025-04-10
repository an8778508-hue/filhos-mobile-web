import 'package:escola/features/diary/models/school_item.dart';
import 'package:escola/features/diary/models/tamplets/question_category_template.dart';
import 'package:escola/features/diary/presentation/widgets/professor_questions/school_list_item.dart';
import 'package:escola/features/diary/presentation/widgets/professor_questions/catergory_template_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TemplatesList extends StatelessWidget {
  final List<QuestionCategoryTemplate> categories;
  final SchoolItem item;
  const TemplatesList(
      {super.key, required this.categories, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.w),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SchoolListItem(
                  item: item,
                  titleSize: 21.sp,
                  subTitleSize: 17.sp,
                  showChatIcon: true,
                  hasArrow: false,
                  textColor: Colors.black,
                ),
              ),
            ],
          ),
          ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return CategoryTemplateItem(category: categories[index]);
            },
          ),
        ],
      ),
    );
  }
}
