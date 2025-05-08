import 'package:escola/core/components/my_icon.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/funuctions/global_functions.dart';
import 'package:escola/core/utils/safe_x.dart';
import 'package:escola/features/diary/models/questions_models/check_question.dart';
import 'package:escola/features/diary/models/questions_models/question.dart';
import 'package:escola/features/diary/models/questions_models/rating_question.dart';
import 'package:escola/features/diary/models/questions_models/select_question.dart';
import 'package:escola/features/diary/models/tamplets/question_template.dart';
import 'package:escola/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:escola/features/diary/presentation/widgets/professor_questions/items_to_send.dart/check_menu_item.dart';
import 'package:escola/features/diary/presentation/widgets/professor_questions/items_to_send.dart/rating_menu_item.dart';
import 'package:escola/features/diary/presentation/widgets/professor_questions/items_to_send.dart/select_menu_item.dart';
import 'package:escola/features/diary/presentation/widgets/professor_questions/select_menu_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/localization/localization_keys.dart';

class DropDownQuestionMenu extends StatefulWidget {
  final QuestionTemplate question;

  const DropDownQuestionMenu({
    Key? key,
    required this.question,
  }) : super(key: key);

  @override
  State<DropDownQuestionMenu> createState() => _DropDownQuestionMenuState();
}

class _DropDownQuestionMenuState extends State<DropDownQuestionMenu> {
  List<SelectItem>? items = [];

  late bool isRating;
  late bool isCheck;

  @override
  void initState() {
    isRating = widget.question.type == QuestionType.rating;
    isCheck = widget.question.type == QuestionType.checkbox;
    super.initState();
  }

  @override
  void didChangeDependencies() {
    adjustItems();
    super.didChangeDependencies();
  }

  void adjustItems() {
    items = widget.question.selectItems;
  }

  @override
  Widget build(BuildContext context) {
    if ((items == null || items!.isEmpty == true) && !isRating) {
      return const SizedBox();
    }
    int length = getLength();

    return PopupMenuButton<dynamic>(
      padding: EdgeInsets.zero,
      shadowColor: Colors.white,
      color: Colors.white,
      elevation: 0,
      constraints: BoxConstraints(
        minWidth: isRating ? 350.w : 200.w,
        maxWidth: MediaQuery.of(context).size.width,
      ),
      position: PopupMenuPosition.under,
      child: SelectMenuButton(question: widget.question),
      itemBuilder: (_) => List.generate(
        length + 1,
        (index) {
          return getMenuItem(
            context: context,
            index: index,
            question: widget.question,
            item: index == 0 ? null : items?[index - 1],
            isLast: index - 1 == length - 1,
          );
        },
      ),
      onSelected: (dynamic value) {
        sendQuestion(value, widget.question);
      },
    );
  }

  int getLength() {
    return isRating ? 5 : items!.length;
  }

  sendQuestion(dynamic value, QuestionTemplate question) {
    if (value == -1) {
      context.read<DiaryBloc>().add(RemoveQuestion(
            questionId: question.id,
            categoryId: question.categoryId,
          ));
    } else if (value is SelectItem) {
      final selectQuestion = SelectQuestion(
        id: question.id,
        label: question.title,
        items: [value],
      );
      context.read<DiaryBloc>().add(AddQuetsion(
            question: selectQuestion,
            categoryId: question.categoryId,
          ));
    } else if (question.type == QuestionType.rating) {
      final ratingQuestion = RatingQuestion(
        id: question.id,
        label: question.title,
        rating: value,
      );
      context.read<DiaryBloc>().add(AddQuetsion(
            question: ratingQuestion,
            categoryId: question.categoryId,
          ));
    } else if (question.type == QuestionType.checkbox) {
      final checkQuestion = CheckQuestion(
        id: question.id,
        title: question.title,
        value: value,
      );
      context.read<DiaryBloc>().add(
            AddQuetsion(
              question: checkQuestion.copyWith(
                  icon_value: items?.safeFirstWhere((element) => element.value == value)?.icon_value),
              categoryId: question.categoryId,
            ),
          );
    }
  }

  PopupMenuItem<dynamic> getMenuItem({
    required BuildContext context,
    required QuestionTemplate question,
    required SelectItem? item,
    required bool isLast,
    required int index,
  }) {
    final isRating = widget.question.type == QuestionType.rating;
    final isCheck = widget.question.type == QuestionType.checkbox;

    return PopupMenuItem<dynamic>(
      value: getValue(index: index, question: question, item: item),
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              margin: EdgeInsets.symmetric(vertical: 8.h),
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: index == 0
                  ? Text(
                LocalizationKeys.choose.tr(context),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    )
                  : isRating
                      ? RatingMenuItem(index: index - 1, question: question)
                      : SelectMenuItem(question: question, item: item)),
          if (!isLast) ...[
            SizedBox(height: 3.h),
            Container(
              height: 1.h,
              color: context.colors.primaryLighter.withOpacity(0.5),
            ),
          ]
        ],
      ),
    );
  }

  dynamic getValue({
    required QuestionTemplate question,
    required SelectItem? item,
    required int index,
  }) {
    if (index == 0) {
      return -1;
    }
    if (isRating) {
      return RatingMenuItem.getRatingCount(index - 1).toInt();
    } else if (isCheck) {
      print('_DropDownQuestionMenuState.getValue');
      return item?.value ?? '';
    } else {
      return item;
    }
  }
}

Widget getDynamicQuestionValue({
  required String? icon_value,
  required BuildContext context,
  required bool isAnswer,
}) {
  late Widget widget;
  switch (icon_value) {
    case '0':
      widget = RatingGenericIcon(rating: 0.0, isAnswer: isAnswer);
    case '1':
      widget = RatingGenericIcon(rating: 1.0, isAnswer: isAnswer);
    case '2':
      widget = RatingGenericIcon(rating: 2.0, isAnswer: isAnswer);
    case '3':
      widget = RatingGenericIcon(rating: 3.0, isAnswer: isAnswer);
    case 'sad':
      widget = MyIcon(assetsPath('sad_1'),size: 20.h,);
    case 'regular':
      widget = MyIcon(assetsPath('regular'),size: 20.h,);
    case 'smile':
      widget = MyIcon(assetsPath('smile'),size: 20.h,);
    case 'happy':
      widget = MyIcon(assetsPath('happy'),size: 20.h,);
    case 'false':
      widget = CheckMenuItem(checked: false);
    default:
      return SizedBox();
  }
  return Row(
    children: [
      SizedBox(width: 10.w),
      widget,
      SizedBox(width: 10.w),
    ],
  );
}

class RatingGenericIcon extends StatelessWidget {
  const RatingGenericIcon({
    Key? key,
    required this.rating,
    required this.isAnswer,
  }) : super(key: key);
  final double rating;
  final bool isAnswer;

  @override
  Widget build(BuildContext context) {
    return RatingBar.builder(
      initialRating: rating,
      minRating: 1,
      direction: Axis.horizontal,
      allowHalfRating: true,
      itemSize: isAnswer ? 35.w : 50.w,
      itemCount: 3,
      unratedColor: const Color(0xffdedede),
      itemPadding: EdgeInsets.symmetric(horizontal: 1.w),
      itemBuilder: (context, _) => const Icon(
        Icons.star,
        color: Colors.amber,
      ),
      ignoreGestures: true,
      onRatingUpdate: (rating) {},
    );
  }
}
