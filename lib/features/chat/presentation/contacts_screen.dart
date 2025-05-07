import 'package:escola/features/chat/presentation/professor_contacts.dart';
import 'package:escola/features/chat/presentation/widgets/children_with_no_messages.dart';
import 'package:escola/features/chat/presentation/widgets/empty_messages.dart';
import 'package:escola/features/diary/models/child_model.dart';

import 'package:escola/flavors/app_flavors.dart';
import 'package:escola/core/components/fields/search_field.dart';
import 'package:escola/core/components/widgets/app_bar.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/chat/models/last_message.dart';
import 'package:escola/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:escola/features/chat/presentation/widgets/last_messages/last_messages_list.dart';
import 'package:escola/features/chat/presentation/widgets/last_messages/global_search_list.dart';
import 'package:escola/features/search/bloc/search_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ContactsScreen extends StatefulWidget {
  final GroupType? groupType;
  const ContactsScreen({super.key, this.groupType});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  bool showSearchAppBar = false;
  final TextEditingController _searchController = TextEditingController();
  List<ChildModel> chidrenWithNoMessages = [];

  @override
  void initState() {
    context.read<ChatBloc>().add(GetParentChildren());

    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    List<LastMessage> lastMessages = context.watch<ChatBloc>().lastMessages;
    if (context.isProfessors && widget.groupType != null) {
      lastMessages = context.read<ChatBloc>().getLastMessagesGroup(widget.groupType!);
    }

    return BlocProvider<SearchBloc>(
      create: (context) => di<SearchBloc>(),
      child: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChildrenSucceed) {
            setState(() => chidrenWithNoMessages = state.filteredChildren);
          }
        },
        builder: (context, state) {
          return Builder(
            builder: (context) => Scaffold(
              appBar: MyAppBar(
                title: LocalizationKeys.chat.tr(context),
                actionWidget: IconButton(
                  onPressed: () => toggleSearch(context),
                  icon: Icon(
                    showSearchAppBar ? Icons.close : Icons.search,
                    size: 26.h,
                    color: context.colors.background,
                  ),
                ),
              ),
              body: state is LastMessagesLoading || state is ChildrenLoading
                  ? const Center(child: CircularProgressIndicator())
                  : BlocBuilder<SearchBloc, SearchState>(
                      builder: (context, searchState) {
                        final globalSearchResult = context.watch<SearchBloc>().globalSearchResult;
                        return Column(
                          children: [
                            if (showSearchAppBar) ...[
                              SearchField(
                                inAppBar: true,
                                hint: searchHint(widget.groupType==GroupType.internals),
                                showClearButton: globalSearchResult != null,
                                onClearSearch: () => toggleSearch(context),
                                onSearch: (value) => _onSearch(context, value),
                                controller: _searchController,
                              )
                            ],
                            Expanded(
                              child: Container(
                                color: Colors.white,
                                child: searchState is SearchLoading
                                    ? const Center(child: CircularProgressIndicator())
                                    : globalSearchResult != null
                                        ? GlobalSearchList(searchResult: globalSearchResult)
                                        : lastMessages.isEmpty && chidrenWithNoMessages.isEmpty
                                            ? const Center(child: EmptyMessages())
                                            : SingleChildScrollView(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    LastMessagesList(lastMessages: lastMessages),
                                                    if (context.isParents) ...[
                                                      ChildrenWithNoMessages(
                                                        lastMessages: lastMessages,
                                                        children: chidrenWithNoMessages,
                                                      ),
                                                    ]
                                                  ],
                                                ),
                                              ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          );
        },
      ),
    );
  }

  String searchHint(bool isInternal) {
    return context.isParents
        ? LocalizationKeys.search_by_professor_name.tr(context)
        : isInternal ? LocalizationKeys.search_by_professor_name.tr(context) : LocalizationKeys.search_by_child_name.tr(context);
  }

  void _onSearch(BuildContext context, String value) {
    if (stringNotNullOrEmpty(value)) {
      context.read<SearchBloc>().add(context.isParents ? ProfessorSearch(query: value) : GlobalSearch(query: value,isTeacher: context.isProfessors));
    }
  }

  void toggleSearch(BuildContext context) {
    if (showSearchAppBar) {
      context.read<SearchBloc>().add(ClearSearch());
    }
    _searchController.clear();
    setState(() => showSearchAppBar = !showSearchAppBar);
  }
}
