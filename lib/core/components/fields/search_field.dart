import 'dart:async';

import 'package:escola/core/components/empty/empty_widget.dart';
import 'package:escola/core/components/fields/custom_text_field.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/funuctions/global_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SearchField extends StatefulWidget {
  final String? hint;
  final TextEditingController controller;
  final Function? onTap;
  final Function(String) onSearch;
  final Function()? onClearSearch;
  final bool showClearButton, inAppBar;
  final Color? backgroundColor;

  const SearchField(
      {super.key,
      this.onTap,
      this.hint,
      required this.controller,
      required this.onSearch,
      this.onClearSearch,
      this.showClearButton = false,
      this.backgroundColor,
      this.inAppBar = false});

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  Timer? _debounce;

  @override
  dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.onTap != null) widget.onTap!();
      },
      child: Container(
        color: widget.inAppBar ? context.colors.primary : null,
        padding: widget.inAppBar ? EdgeInsets.symmetric(horizontal: 18.w).copyWith(bottom: 20.w, top: 10.w) : null,
        child: CustomTextField(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.w),
          onSubmit: (value) {
            widget.onSearch(value.trim());
          },
          hintColor: Colors.black.withOpacity(0.7),
          onChanged: (value) {
            if (_debounce?.isActive ?? false) _debounce?.cancel();
            _debounce = Timer(const Duration(seconds: 1), () {
              if (value.trim().isEmpty) {
                widget.onClearSearch?.call();
              }
              if (value.trim().length < 3) return;
              if (value.trim().length >= 3) {
                FocusScope.of(context).unfocus();
                widget.onSearch(value.trim());
              }
              // FocusScope.of(context).unfocus();
              // widget.onSearch(value.trim());
            });
          },
          textInputAction: TextInputAction.search,
          backgroundColor: widget.backgroundColor ?? Colors.white,
          controller: widget.controller,
          hint: widget.hint ?? "Search Here",
          contentPaddingHorizontal: 10.w,
          borderRadius: 5.w,
          trailing: GestureDetector(
            onTap: () {
              if (widget.onClearSearch != null) {
                widget.onClearSearch!();
                widget.controller.clear();
              }
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: Icon(
                widget.showClearButton ? Icons.clear : Icons.search,
                color: Colors.black,
                size: 24.w,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EmptySearchResult extends StatelessWidget {
  const EmptySearchResult({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 100.h,
        ),
        EmptyWidget(
          icon: assetsPath('search_result'),
          title: LocalizationKeys.no_search_result_found.tr(context),
          iconColor: context.colors.primary,
        ),
      ],
    );
  }
}
