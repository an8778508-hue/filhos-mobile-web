import 'package:escola/core/models/event_model.dart';
import 'package:escola/core/models/generic_state.dart';

class FeaturedEventsState {
  final GenericListState<EventModel> eventsState;

  const FeaturedEventsState({
    this.eventsState = const GenericListState<EventModel>(),
  });

  FeaturedEventsState copyWith({
    GenericListState<EventModel>? eventsState,
  }) =>
      FeaturedEventsState(
        eventsState: eventsState ?? this.eventsState,
      );

  FeaturedEventsState updateEventsState(
          GenericListState<EventModel> Function(GenericListState<EventModel> s) update) =>
      copyWith(eventsState: update(eventsState));
}
