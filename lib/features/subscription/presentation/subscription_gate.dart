import 'package:escola/features/subscription/bloc/subscription_bloc.dart';
import 'package:escola/features/subscription/bloc/subscription_state.dart';
import 'package:escola/features/subscription/presentation/subscription_expired_screen.dart';
import 'package:escola/features/subscription/presentation/widgets/subscription_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Wraps the admin experience: renders [child] together with a subscription
/// banner, and overlays a full-screen blocking [SubscriptionExpiredScreen]
/// when the subscription is expired.
class SubscriptionGate extends StatefulWidget {
  final SubscriptionBloc bloc;
  final Widget child;
  final VoidCallback? onRenew;

  /// When true the banner is shown above [child]. Set false to only use the
  /// expired-blocking behaviour.
  final bool showBanner;

  const SubscriptionGate({
    super.key,
    required this.bloc,
    required this.child,
    this.onRenew,
    this.showBanner = true,
  });

  @override
  State<SubscriptionGate> createState() => _SubscriptionGateState();
}

class _SubscriptionGateState extends State<SubscriptionGate> {
  @override
  void initState() {
    super.initState();
    widget.bloc.fetch();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.bloc,
      child: BlocBuilder<SubscriptionBloc, SubscriptionState>(
        builder: (context, state) {
          final subscription = state.subscription;

          if (state.isExpired) {
            return SubscriptionExpiredScreen(onRenew: widget.onRenew);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.showBanner && subscription != null)
                SubscriptionBanner(subscription: subscription),
              Expanded(child: widget.child),
            ],
          );
        },
      ),
    );
  }
}
