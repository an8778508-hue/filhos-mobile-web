import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

EventBus eventBus = EventBus();

class EventAcceptedOrRejected {}

class EventAdded {}

mixin EventCubitListener<S> on Cubit<S> {
  final List<StreamSubscription> subs = [];

  listen<T>(void Function(T event)? onData) => subs.add(eventBus.on<T>().listen(onData));

  @override
  Future<void> close() async {
    for (var sub in subs) {
      await sub.cancel();
    }
    return super.close();
  }
}

mixin EventBlocListener<E, S> on Bloc<E, S> {
  final List<StreamSubscription> subs = [];

  listen<T>(void Function(T event)? onData) => subs.add(eventBus.on<T>().listen(onData));

  @override
  Future<void> close() async {
    for (var sub in subs) {
      await sub.cancel();
    }
    return super.close();
  }
}
