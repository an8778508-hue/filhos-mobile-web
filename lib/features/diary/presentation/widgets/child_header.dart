import 'package:escola/core/components/icons/avatar.dart';
import 'package:escola/core/components/icons/common_image.dart';
import 'package:escola/core/models/user_model.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/widgets_ext.dart';
import 'package:escola/core/utils/funuctions/widget_functions.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/chat/models/chat_user.dart';
import 'package:escola/features/chat/presentation/chat_screen.dart';
import 'package:escola/features/diary/models/activities.dart';
import 'package:escola/features/diary/models/child_model.dart';
import 'package:escola/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:escola/shared/assets/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChildHeader extends StatefulWidget {
  final ChildModel child;
  final Activity? activity;

  const ChildHeader({super.key, required this.child, this.activity});

  @override
  State<ChildHeader> createState() => _ChildHeaderState();
}

class _ChildHeaderState extends State<ChildHeader> {
  Activity? activity;
  @override
  void initState() {
    activity = widget.activity;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DiaryBloc, DiaryState>(
      listener: (context, state) {
        if (state is DiaryActivitiesLoaded) {
          if (activity == null && state.activities.isNotEmpty) {
            setState(() => activity = state.activities.first);
          }
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.h).copyWith(top: 20.h),
        child: Row(
          children: [
            Avatar(avatar: widget.child.avatar, isChild: true),
            SizedBox(width: 15.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.child.name ?? "",
                        style: TextStyle(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w700,
                          color: context.colors.textColor,
                        ),
                      ),
                      if (activity != null)
                        CommonImage(
                          imageUrl: Assets.icons.chatIcon.path,
                          size: 30.w,
                          color: context.colors.primary,
                        ).splash(onPressed: () => openChatScreen(context))
                    ],
                  ),
                  if (stringNotNullOrEmpty(widget.child.classRoom)) ...[
                    SizedBox(height: 10.h),
                    Text(
                      widget.child.classRoom!,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w300,
                        color: context.colors.textColor,
                      ),
                    ),
                  ]
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void openChatScreen(BuildContext context) {
    final professor = activity?.professor;
    if (professor != null && professor.id != null) {
      ChatUser contact = ChatUser(
          id: professor.id.toString(), name: professor.name, avatar: professor.avatar, type: UserType.professor);
      WidgetFunctions.navigateTo(context, ChatScreen(contact: contact, child: widget.child));
    }
  }
}
