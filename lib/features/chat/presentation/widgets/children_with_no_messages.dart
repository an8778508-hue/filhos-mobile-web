import 'package:escola/core/utils/funuctions/widget_functions.dart';
import 'package:escola/features/chat/models/last_message.dart';
import 'package:escola/features/chat/presentation/chat_screen.dart';
import 'package:escola/features/chat/presentation/styles/chat_styles.dart';
import 'package:escola/features/diary/models/child_model.dart';
import 'package:escola/features/diary/models/school_item.dart';
import 'package:escola/features/diary/presentation/widgets/professor_questions/school_list_item.dart';

import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/features/chat/presentation/bloc/chat_bloc.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChildrenWithNoMessages extends StatelessWidget {
  final List<ChildModel> children;
  final List<LastMessage> lastMessages;
  const ChildrenWithNoMessages({super.key, required this.children, required this.lastMessages});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (children.isNotEmpty) ...[
          if (lastMessages.isNotEmpty) ...[
            SizedBox(height: 16.h),
            Container(
              width: 300.w,
              height: 2.h,
              color: const Color(0xffececec),
            ),
            SizedBox(height: 16.h),
          ],
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: children.length,
            itemBuilder: (context, index) {
              final child = children[index];
              String? name = ChatBloc.getContactFullName(context, null, child.name);

              final childToSchoolItem = SchoolItem(
                name: name,
                avatar: child.avatar,
                id: child.id,
                type: SchoolItemType.childType,
                classRoom: LocalizationKeys.no_messages_yet.tr(context),
                parent: child.parent,
              );
              return Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      WidgetFunctions.navigateTo(context, ChatScreen(contact: null, child: child));
                    },
                    child: SchoolListItem(
                      item: childToSchoolItem,
                      hasArrow: false,
                      verticalPadding: 0,
                      hasBorder: false,
                      textColor: ChatColors.contactNameColor,
                    ),
                  ),
                  if (index != children.length - 1) ...[
                    SizedBox(height: 16.h),
                    Container(
                      width: 300.w,
                      height: 2.h,
                      color: const Color(0xffececec),
                    ),
                    SizedBox(height: 16.h),
                  ]
                ],
              );
            },
          )
        ]
      ],
    );
  }
}
