import 'package:flutter/material.dart';

/// Full-screen blocking overlay shown when the nursery subscription has
/// expired. It deliberately covers the whole screen so the rest of the app
/// cannot be used until the subscription is renewed.
class SubscriptionExpiredScreen extends StatelessWidget {
  static const Key blockingKey = Key('subscription_expired_blocking');

  final VoidCallback? onRenew;

  const SubscriptionExpiredScreen({super.key, this.onRenew});

  @override
  Widget build(BuildContext context) {
    return Material(
      key: blockingKey,
      color: Colors.black.withOpacity(0.85),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_clock, color: Colors.white, size: 72),
                const SizedBox(height: 24),
                const Text(
                  'Subscription expired',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your nursery subscription has expired. Please renew to continue using the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onRenew,
                  child: const Text('Renew subscription'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
