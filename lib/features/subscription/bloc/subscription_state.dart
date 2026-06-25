import 'package:escola/core/models/generic_state.dart';
import 'package:escola/features/subscription/model/subscription_model.dart';

class SubscriptionState {
  final GenericDataState<SubscriptionModel> subscriptionState;

  const SubscriptionState({
    this.subscriptionState = const GenericDataState<SubscriptionModel>(),
  });

  SubscriptionModel? get subscription => subscriptionState.data;

  bool get isExpired => subscriptionState.data?.isExpired ?? false;

  SubscriptionState copyWith({
    GenericDataState<SubscriptionModel>? subscriptionState,
  }) =>
      SubscriptionState(
        subscriptionState: subscriptionState ?? this.subscriptionState,
      );

  SubscriptionState updateSubscriptionState(
    GenericDataState<SubscriptionModel> Function(GenericDataState<SubscriptionModel> s) update,
  ) =>
      copyWith(subscriptionState: update(subscriptionState));
}
