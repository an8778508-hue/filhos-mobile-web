import 'package:flutter/material.dart';

class AutoScroller extends StatefulWidget {
  const AutoScroller({
    super.key,
    required this.child,
    required this.height,
    this.padding,
  });

  final Widget child;
  final double height;
  final EdgeInsetsGeometry? padding;

  @override
  State<AutoScroller> createState() => _AutoScrollerState();
}

class _AutoScrollerState extends State<AutoScroller> {
  late final ScrollController controller;

  @override
  void initState() {
    super.initState();
    controller = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _animate();
    });
  }

  _animate({bool reverse = false}) async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted && controller.hasClients) {
      await controller.animateTo(
        reverse ? 0 : controller.position.maxScrollExtent,
        duration: const Duration(seconds: 5),
        curve: Curves.easeInOut,
      );
    }
    await _animate(reverse: !reverse);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: SingleChildScrollView(
        controller: controller,
        physics: const NeverScrollableScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: widget.padding,
        child: widget.child,
      ),
    );
  }
}
