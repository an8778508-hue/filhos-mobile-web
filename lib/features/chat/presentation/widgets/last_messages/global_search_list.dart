import 'package:escola/core/components/fields/search_field.dart';
import 'package:escola/core/components/icons/avatar.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/models/user_model.dart';
import 'package:escola/core/utils/funuctions/widget_functions.dart';
import 'package:escola/features/chat/models/chat_user.dart';
import 'package:escola/features/chat/presentation/chat_screen.dart';
import 'package:escola/features/diary/models/child_model.dart';
import 'package:escola/features/diary/models/school_item.dart';
import 'package:escola/features/search/models/global_search.dart';
import 'package:escola/flavors/app_flavors.dart';
import 'package:escola/shared/assets/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GlobalSearchList extends StatelessWidget {
  final GlobalSearchResult searchResult;
  final bool forChat;

  const GlobalSearchList({super.key, required this.searchResult, this.forChat = true});

  @override
  Widget build(BuildContext context) {
    for (var element in searchResult.parents) {
      debugPrint("Parentttttttttt: ${element.name}");
    }
    for (var element in searchResult.teachers) {
      debugPrint("Teacherrrrrrrrrrr: ${element.name}");
    }
    for (var element in searchResult.children) {
      debugPrint("Childddddddddddddddd: ${element.name}");
    }
    if (searchResult.teachers.isEmpty &&
        searchResult.parents.isEmpty &&
        searchResult.children.isEmpty &&
        searchResult.levels.isEmpty) {
      return const EmptySearchResult();
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (searchResult.teachers.isNotEmpty) ...[
            SearchListTitle(title: LocalizationKeys.professors.tr(context)),
            UsersSearchResult(items: searchResult.teachers),
          ],
          if (searchResult.parents.isNotEmpty && !forChat) ...[
            SearchListTitle(title: LocalizationKeys.parents.tr(context)),
            UsersSearchResult(items: searchResult.parents),
          ],
          if (searchResult.children.isNotEmpty) ...[
            // SearchListTitle(title: LocalizationKeys.all_children.tr(context)),
            UsersSearchResult(items: searchResult.children),
          ],
          if (searchResult.levels.isNotEmpty && !forChat) ...[
            SearchListTitle(title: LocalizationKeys.levels.tr(context)),
            UsersSearchResult(items: searchResult.levels),
          ],
        ],
      ),
    );
  }
}

class SearchListTitle extends StatelessWidget {
  final String title;
  const SearchListTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Text(
            title,
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600, color: Colors.black),
          ),
        ),
        Container(
          width: double.infinity,
          height: 1.5.h,
          color: const Color(0xffececec),
        ),
      ],
    );
  }
}

class UsersSearchResult extends StatelessWidget {
  final List<SchoolItem> items;

  const UsersSearchResult({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        final String defaultAvatar =
            context.isParents ? Assets.icons.maleProfessor.path : Assets.icons.defaultAvatar.path;

        return GestureDetector(
          onTap: () {
            final contact = getChatUserFromSchoolItem(item);
            ChildModel? child;
            if (item.type == SchoolItemType.childType) {
              child = item.getChildModel();
            }
            WidgetFunctions.navigateTo(context, ChatScreen(contact: contact, child: child));
          },
          child: Container(
            color: Colors.transparent,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w).copyWith(top: 16.h),
              child: Column(
                children: [
                  Row(
                    children: [
                      Avatar(
                        avatar: item.avatar,
                        defaultAvatar: defaultAvatar,
                        size: 50.w,
                      ),
                      SizedBox(width: 20.w),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name ?? "",
                                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.black),
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 18.sp, color: Colors.black)
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15.h),
                  if (index != items.length - 1) ...[
                    Container(
                      width: double.infinity,
                      height: 1.5.h,
                      color: const Color(0xffececec),
                    ),
                    SizedBox(height: 15.h),
                  ]
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  ChatUser getChatUserFromSchoolItem(SchoolItem item) {
    return ChatUser(
      id: item.id.toString(),
      name: item.name,
      avatar: item.avatar,
      type: item.type == SchoolItemType.parentType ? UserType.parent : UserType.professor,
    );
  }
}
