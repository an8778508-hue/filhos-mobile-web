import 'package:escola/core/components/widgets/app_bar.dart';
import 'package:escola/core/components/widgets/error_widget.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/features/chat/models/chat_user.dart';
import 'package:escola/features/chat/presentation/audio_bloc/audio_bloc.dart';
import 'package:escola/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:escola/features/chat/presentation/bloc/images_message_bloc.dart';
import 'package:escola/features/chat/presentation/bloc/text_message_bloc.dart';
import 'package:escola/features/chat/presentation/widgets/message_actions.dart';
import 'package:escola/features/chat/presentation/widgets/messages_list.dart';
import 'package:escola/features/diary/models/child_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/single_child_widget.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser? contact;
  final ChildModel? child;
  const ChatScreen({
    super.key,
    required this.contact,
    required this.child,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  ChatUser? _contact;
  @override
  void initState() {
    _contact = widget.contact;
    getTeachersAndMessages();
    super.initState();
  }

  @override
  dispose() {
    di<ChatBloc>().messagesSubscription?.cancel();
    super.dispose();
  }

  void getTeachersAndMessages() {

    if (widget.child != null) {
      debugPrint('${widget.child} widget.child');
      getChildTeachers();
    } else {
      getMessages(_contact);
    }
  }

  void getMessages(ChatUser? contact) {
    if (contact != null) {
      context.read<ChatBloc>().add(GetMessages(contact: contact, child: widget.child));
    }
  }

  void getChildTeachers() => context.read<ChatBloc>().add(GetChildTeachers(child: widget.child!));

  @override
  Widget build(BuildContext context) {
    return ProvidersHanlder(
      providers: _contact != null ? getProviders() : [],
      child: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error.message)));
          } else if (state is MessagesLoaded) {
            context.read<AudioBloc>().add(InitAudioPlayers(messages: state.messages));
          } else if (state is TeachersSucceed) {
            if (state.teachers.isNotEmpty) {
              setState(() => _contact = state.teachers.first);
            }
            getMessages(_contact);
          }
        },
        builder: (context, state) {
          String? name = ChatBloc.getContactFullName(context, widget.contact, widget.child?.name);
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: MyAppBar(
              title: name ?? LocalizationKeys.chat.tr(context),
            ),
            body: (state is MessagesLoading || state is TeachersLoading)
                ? const Center(child: CircularProgressIndicator())
                : state is MessagesFailed
                    ? Center(
                        child: ErrorScreen(errorText: state.failure.message, onRetry: () => getTeachersAndMessages()))
                    : _contact == null
                        ? const SizedBox()
                        : Container(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [Expanded(child: MessagesList()), ChatActions()],
                            ),
                          ),
          );
        },
      ),
    );
  }

  getProviders() => [
        BlocProvider<TextMessageBloc>(
          create: (context) => TextMessageBloc(contactUser: _contact, chatBloc: di<ChatBloc>(), child: widget.child),
        ),
        BlocProvider<ImagesMessageBloc>(
          create: (context) => ImagesMessageBloc(contactUser: _contact, chatBloc: di<ChatBloc>(), child: widget.child),
        ),
        BlocProvider<AudioBloc>(
          create: (context) => AudioBloc(contactUser: _contact, chatBloc: di<ChatBloc>(), child: widget.child),
        ),
      ];
}

class ProvidersHanlder extends StatelessWidget {
  final Widget child;
  final List<SingleChildWidget> providers;
  const ProvidersHanlder({
    super.key,
    required this.child,
    required this.providers,
  });

  @override
  Widget build(BuildContext context) {
    if (providers.isNotEmpty) {
      return MultiBlocProvider(
        providers: providers,
        child: child,
      );
    }
    return child;
  }
}
