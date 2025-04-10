import 'package:flutter/material.dart';

class Pagination extends StatelessWidget {
  const Pagination({
    Key? key,
    required this.child,
    required this.onLoadMore,
    required this.noMore,
  }) : super(key: key);

  final Widget child;
  final Function() onLoadMore;
  final bool Function() noMore;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollUpdateNotification>(
      onNotification: (notification) {
        if (noMore()) {
        } else {
          if (notification.metrics.extentAfter <= 40) {
            onLoadMore();
            return true;
          }
        }
        return false;
      },
      child: child,
    );
  }
}
