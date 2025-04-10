import 'package:escola/core/components/widgets/error_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PaginationWidget<T> extends StatefulWidget {
  final PaginationController<T> controller;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget loadingWidget;
  final Widget? loadingMoreWidget;
  final bool isLoading;
  final Widget emptyWidget;
  final String? error;
  final Widget? errorWiget;
  const PaginationWidget({
    super.key,
    required this.controller,
    required this.itemBuilder,
    required this.loadingWidget,
    required this.isLoading,
    required this.emptyWidget,
    this.error,
    this.errorWiget,
    this.loadingMoreWidget,
  });

  @override
  State<PaginationWidget<T>> createState() => _PaginationWidgetState<T>();
}

class _PaginationWidgetState<T> extends State<PaginationWidget<T>> {
  @override
  void initState() {
    widget.controller.addListener(() {
      if (shouldLoadMore()) {
        if (widget.controller.noMorePages) return;

        widget.controller.currentPage = widget.controller.currentPage + 1;
        widget.controller.getNextPage(context, widget.controller.currentPage);
      }
    });
    super.initState();
  }

  bool shouldLoadMore() {
    double delta = (MediaQuery.of(context).size.height) * 0.1;

    final currentPixels = widget.controller.position.pixels;

    final maxScrollExtent = widget.controller.position.maxScrollExtent;

    final bool shouldLoadMore =
        currentPixels >= (maxScrollExtent - delta) && !widget.isLoading;

    return shouldLoadMore;
  }

  @override
  Widget build(BuildContext context) {
    if ((emptyList() || nullList())) {
      if (widget.isLoading) {
        return Center(child: widget.loadingWidget);
      } else if (widget.error != null) {
        return Center(
          child: widget.errorWiget ??
              ErrorScreen(
                errorText: widget.error!,
                onRetry: () {
                  widget.controller
                      .getNextPage(context, widget.controller.currentPage);
                },
              ),
        );
      } else {
        return widget.emptyWidget;
      }
    }

    return ListView.builder(
      shrinkWrap: true,
      controller: widget.controller,
      itemCount: widget.controller.items!.length,
      padding: EdgeInsets.only(bottom: 18.h),
      itemBuilder: (context, index) {
        final item = widget.controller.items![index];
        final isLast = index == widget.controller.items!.length - 1;
        return Column(
          children: [
            widget.itemBuilder(context, item, index),
            if (isLast && widget.isLoading) ...[
              const SizedBox(height: 20),
              widget.loadingMoreWidget ?? widget.loadingWidget
            ]
          ],
        );
      },
    );
  }

  bool emptyList() => widget.controller.items == [];

  bool nullList() => widget.controller.items == null;
}

class PaginationController<T> extends ScrollController {
  List<T>? items;
  final Function(BuildContext cotext, int page) getNextPage;

  bool noMorePages = false;
  int currentPage = 1;
  PaginationController({
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
    super.onAttach,
    super.onDetach,
    required this.getNextPage,
  });

  void addPage(List<T> newItems) {
    if (noMorePages) return;
    if (newItems.isEmpty) {
      noMorePages = true;
      return;
    }
    if (items != null) {
      items!.addAll(newItems);
    } else {
      items = newItems;
    }
  }
}
