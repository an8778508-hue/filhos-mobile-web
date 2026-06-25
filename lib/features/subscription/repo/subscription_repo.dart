import 'package:dartz/dartz.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/network/network_models.dart';
import 'package:escola/features/subscription/model/subscription_model.dart';

class SubscriptionRepo {
  final NetworkClientRepository networkClient;

  SubscriptionRepo({required this.networkClient});

  /// Current subscription for the nursery.
  Future<Either<Failure, SubscriptionModel>> getSubscription() async {
    return networkClient.handleRequest(
      const NetworkRequest(
        method: HttpMethod.get,
        url: 'admin/nurseries/subscription',
      ),
      onSuccess: (json) => SubscriptionModel.fromJson(json['data']),
    );
  }

  /// Start the 14-day free trial.
  Future<Either<Failure, SubscriptionModel>> startTrial() async {
    return networkClient.handleRequest(
      const NetworkRequest(
        method: HttpMethod.post,
        url: 'admin/nurseries/trial',
      ),
      onSuccess: (json) => SubscriptionModel.fromJson(json['data']),
    );
  }

  /// Upgrade the nursery to a paid (monthly|annual) plan.
  Future<Either<Failure, SubscriptionModel>> upgrade({
    required String plan,
    required int childCount,
    required double pricePerChild,
  }) async {
    return networkClient.handleRequest(
      NetworkRequest(
        method: HttpMethod.post,
        url: 'admin/nurseries/subscription/upgrade',
        body: {
          'plan': plan,
          'child_count': childCount,
          'price_per_child': pricePerChild,
        },
      ),
      onSuccess: (json) => SubscriptionModel.fromJson(json['data']),
    );
  }
}
