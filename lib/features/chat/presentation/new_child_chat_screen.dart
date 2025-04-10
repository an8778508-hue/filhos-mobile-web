import 'package:escola/core/components/widgets/app_bar.dart';
import 'package:escola/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:escola/features/diary/models/child_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NewChildChatScreen extends StatefulWidget {
  final ChildModel child;
  const NewChildChatScreen({super.key, required this.child});

  @override
  State<NewChildChatScreen> createState() => _NewChildChatScreenState();
}

class _NewChildChatScreenState extends State<NewChildChatScreen> {
  @override
  void initState() {
    getChildTeachers();
    super.initState();
  }

  void getChildTeachers() {
    context.read<ChatBloc>().add(GetChildTeachers(child: widget.child));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.white, appBar: MyAppBar(title: ""));
  }
}
