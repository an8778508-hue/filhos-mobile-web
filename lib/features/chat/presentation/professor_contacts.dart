import 'package:escola/core/components/icons/avatar.dart';
import 'package:escola/core/components/widgets/app_bar.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/funuctions/widget_functions.dart';
import 'package:escola/features/chat/models/last_message.dart';
import 'package:escola/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:escola/features/chat/presentation/contacts_screen.dart';
import 'package:escola/features/chat/presentation/styles/chat_styles.dart';
import 'package:escola/shared/assets/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfessorsContacts extends StatelessWidget {
  const ProfessorsContacts({super.key});

  @override
  Widget build(BuildContext context) {
    final List<LastMessage> professorsMessages = context.watch<ChatBloc>().getLastMessagesGroup(GroupType.internals);
    final List<LastMessage> parentMessages = context.watch<ChatBloc>().getLastMessagesGroup(GroupType.external);

    return Scaffold(
      appBar: MyAppBar(
        title: LocalizationKeys.chat.tr(context),
      ),
      body: ListView.builder(
        itemCount: 2,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 32.h),
        itemBuilder: (context, index) {
          return Column(
            children: [
              MessagesGroup(
                groupType: index == 0 ? GroupType.internals : GroupType.external,
                lastMessages: index == 0 ? professorsMessages : parentMessages,
              ),
              SizedBox(height: 15.h),
              if (index != 2 - 1) ...[
                Container(
                  width: 250.w,
                  height: 2.h,
                  color: const Color(0xffececec),
                ),
                SizedBox(height: 15.h),
              ]
            ],
          );
        },
      ),
    );
  }
}

class MessagesGroup extends StatelessWidget {
  final GroupType groupType;
  final List<LastMessage> lastMessages;
  const MessagesGroup({super.key, required this.groupType, required this.lastMessages});

  @override
  Widget build(BuildContext context) {
    int unReadMessagesCount = 0;
    for (var i = 0; i < lastMessages.length; i++) {
      final lastMessage = lastMessages[i];
      unReadMessagesCount += lastMessage.unReadCount ?? 0;
    }

    return GestureDetector(
      onTap: () {
        WidgetFunctions.navigateTo(context, ContactsScreen(groupType: groupType));
      },
      child: Container(
        color: Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Avatar(
              avatar:
                  groupType == GroupType.internals ? Assets.icons.professorsGroup.path : Assets.icons.parentsGroup.path,
              size: 50.w,
            ),
            SizedBox(width: 20.w),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          groupType == GroupType.internals
                              ? LocalizationKeys.internal.tr(context)
                              : LocalizationKeys.external.tr(context),
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: ChatColors.contactNameColor,
                          ),
                        ),
                        Text(
                          groupType == GroupType.internals
                              ? LocalizationKeys.chat_with_collagess.tr(context)
                              : LocalizationKeys.chat_with_parents.tr(context),
                          style: TextStyle(
                              fontSize: 15.sp, fontWeight: FontWeight.w500, color: ChatColors.messageContentColor),
                        )
                      ],
                    ),
                  ),
                  if (unReadMessagesCount > 0) ...[
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.w),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unReadMessagesCount.toString(),
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w)
                  ],
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.black,
                      size: 25.w,
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum GroupType { external, internals }
