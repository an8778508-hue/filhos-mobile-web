import 'package:escola/core/dependency_injection/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/user_bloc.dart';
import '../bloc/user_state.dart';

class UserBuilder extends StatelessWidget {
  const UserBuilder({
    super.key,
    required this.builder,
    required this.buildWhen,
  });

  final Widget Function(BuildContext context, UserState state) builder;
  final BlocBuilderCondition<UserState> buildWhen;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      bloc: di<UserBloc>(),
      buildWhen: buildWhen,
      builder: builder,
    );
  }
}

class UserConsumer extends StatelessWidget {
  const UserConsumer({
    super.key,
    required this.builder,
    required this.listener,
    required this.buildWhen,
    required this.listenWhen,
  });

  final Widget Function(BuildContext context, UserState state) builder;
  final void Function(BuildContext context, UserState state) listener;
  final BlocBuilderCondition<UserState> buildWhen;
  final BlocListenerCondition<UserState> listenWhen;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserBloc, UserState>(
      bloc: di<UserBloc>(),
      buildWhen: buildWhen,
      listenWhen: listenWhen,
      listener: listener,
      builder: builder,
    );
  }
}

class UserSelector<T> extends StatelessWidget {
  const UserSelector({
    super.key,
    required this.builder,
    required this.selector,
  });

  final BlocWidgetBuilder<T> builder;
  final T Function(UserState state) selector;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<UserBloc, UserState, T>(
      bloc: di<UserBloc>(),
      selector: selector,
      builder: builder,
    );
  }
}

class UserListener extends StatelessWidget {
  const UserListener({
    super.key,
    required this.listener,
    required this.listenWhen,
    required this.child,
  });

  final void Function(BuildContext context, UserState state) listener;
  final BlocListenerCondition<UserState> listenWhen;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserBloc, UserState>(
      bloc: di<UserBloc>(),
      listenWhen: listenWhen,
      listener: listener,
      child: child,
    );
  }
}
