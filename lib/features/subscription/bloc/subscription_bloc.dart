import 'package:bloc/bloc.dart';
import 'package:escola/features/subscription/bloc/subscription_state.dart';
import 'package:escola/features/subscription/repo/subscription_repo.dart';

class SubscriptionBloc extends Cubit<SubscriptionState> {
  SubscriptionBloc(this.subscriptionRepo) : super(const SubscriptionState());

  final SubscriptionRepo subscriptionRepo;

  Future<void> fetch() async {
    emit(state.updateSubscriptionState((s) => s.asLoading()));
    final result = await subscriptionRepo.getSubscription();
    result.fold(
      (failure) => emit(state.updateSubscriptionState((s) => s.asFailed(failure))),
      (model) => emit(state.updateSubscriptionState((s) => s.asSuccess(model))),
    );
  }

  Future<void> startTrial() async {
    emit(state.updateSubscriptionState((s) => s.asLoading()));
    final result = await subscriptionRepo.startTrial();
    result.fold(
      (failure) => emit(state.updateSubscriptionState((s) => s.asFailed(failure))),
      (model) => emit(state.updateSubscriptionState((s) => s.asSuccess(model))),
    );
  }

  Future<void> upgrade({
    required String plan,
    required int childCount,
    required double pricePerChild,
  }) async {
    emit(state.updateSubscriptionState((s) => s.asLoading()));
    final result = await subscriptionRepo.upgrade(
      plan: plan,
      childCount: childCount,
      pricePerChild: pricePerChild,
    );
    result.fold(
      (failure) => emit(state.updateSubscriptionState((s) => s.asFailed(failure))),
      (model) => emit(state.updateSubscriptionState((s) => s.asSuccess(model))),
    );
  }
}
