import 'package:escola/core/dependency_injection/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../config.dart';
import '../cubit/cubit.dart';

typedef StateExtractor<S> = dynamic Function(S s);

/// used with [buildWhen] and [listenWhen] functions of [BlocBuilder], [BlocSelector], [BlocListener] and [BlocConsumer]
bool Function(S previousState, S currentState) compareStates<S>(List<StateExtractor<S>> extractors) {
  return (S previousState, S currentState) {
    return extractors.any((extractor) {
      final notEqual = extractor.call(previousState) != extractor.call(currentState);
      // final notNull = extractor.call(currentState) != null;
      return notEqual;
    });
  };
}

class ConfigBuilder extends StatelessWidget {
  const ConfigBuilder({
    Key? key,
    required this.builder,
    required this.buildWhen,
  }) : super(key: key);

  final Widget Function(BuildContext context, Config config) builder;
  final BlocBuilderCondition<Config> buildWhen;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConfigCubit, Config>(
      bloc: di<ConfigCubit>(),
      buildWhen: buildWhen,
      builder: builder,
    );
  }
}

class ConfigConsumer extends StatelessWidget {
  const ConfigConsumer({
    Key? key,
    required this.builder,
    required this.listener,
    required this.buildWhen,
    required this.listenWhen,
  }) : super(key: key);

  final Widget Function(BuildContext context, Config config) builder;
  final void Function(BuildContext context, Config config) listener;
  final BlocBuilderCondition<Config> buildWhen;
  final BlocListenerCondition<Config> listenWhen;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ConfigCubit, Config>(
      bloc: di<ConfigCubit>(),
      buildWhen: buildWhen,
      listenWhen: listenWhen,
      listener: listener,
      builder: builder,
    );
  }
}

class ConfigSelector<T> extends StatelessWidget {
  const ConfigSelector({
    Key? key,
    required this.builder,
    required this.selector,
  }) : super(key: key);

  final BlocWidgetBuilder<T> builder;
  final T Function(Config config) selector;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ConfigCubit, Config, T>(
      bloc: di<ConfigCubit>(),
      selector: selector,
      builder: builder,
    );
  }
}

class ConfigListener extends StatelessWidget {
  const ConfigListener({
    Key? key,
    required this.listener,
    required this.listenWhen,
    required this.child,
  }) : super(key: key);

  final void Function(BuildContext context, Config config) listener;
  final BlocListenerCondition<Config> listenWhen;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConfigCubit, Config>(
      bloc: di<ConfigCubit>(),
      listenWhen: listenWhen,
      listener: listener,
      child: child,
    );
  }
}
