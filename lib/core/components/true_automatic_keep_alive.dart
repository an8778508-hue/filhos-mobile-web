import 'package:flutter/material.dart';

class TrueAutomaticKeepAlive extends StatefulWidget {
  const TrueAutomaticKeepAlive({super.key, required this.child});

  final Widget child;

  @override
  State<TrueAutomaticKeepAlive> createState() => _TrueAutomaticKeepAliveState();
}

class _TrueAutomaticKeepAliveState extends State<TrueAutomaticKeepAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
