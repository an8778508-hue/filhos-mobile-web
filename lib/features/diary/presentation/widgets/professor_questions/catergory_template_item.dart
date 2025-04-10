import 'package:escola/core/components/icons/common_image.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/features/diary/models/tamplets/question_category_template.dart';
import 'package:escola/features/diary/presentation/widgets/professor_questions/question_template_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CategoryTemplateItem extends StatefulWidget {
  final QuestionCategoryTemplate category;
  const CategoryTemplateItem({super.key, required this.category});

  @override
  State<CategoryTemplateItem> createState() => _CategoryTemplateItemState();
}

class _CategoryTemplateItemState extends State<CategoryTemplateItem> {
  bool isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final iconIsSizedBox = CommonImage(imageUrl: widget.category.icon, size: 25.w).build(context) is SizedBox;

    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => isExpanded = !isExpanded),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16.w),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: context.colors.scaffold,
                  width: 1.w,
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (widget.category.icon != null) ...[
                          CommonImage(imageUrl: widget.category.icon, size: 25.w),
                          SizedBox(width: iconIsSizedBox ? 0 : 10.w)
                        ],
                        Expanded(
                          child: Text(
                            (widget.category.title ?? ""),
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w600,
                              color: context.colors.primary,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => isExpanded = !isExpanded),
                    icon: Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 25.w,
                      color: const Color(0xff6d7f9f),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isExpanded) ...[
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: widget.category.questionTamplets.length,
            itemBuilder: (context, index) {
              return Column(
                children: [
                  QuestionTemplateItem(
                    question: widget.category.questionTamplets[index],
                  ),
                ],
              );
            },
          ),
        ]
      ],
    );
  }
}
