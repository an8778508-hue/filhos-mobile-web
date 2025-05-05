import 'dart:async';

import 'package:escola/core/components/fields/custom_text_field.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/diary/models/questions_models/info_question.dart';
import 'package:escola/features/diary/models/tamplets/question_template.dart';
import 'package:escola/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class InfoItem extends StatefulWidget {
  final QuestionTemplate question;
  const InfoItem({super.key, required this.question});

  @override
  State<InfoItem> createState() => _InfoItemState();
}

class _InfoItemState extends State<InfoItem> {
  Timer? _debounce;
  TextEditingController controller = TextEditingController();

  @override
  dispose() {
    _debounce?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.white, width: 1.w),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stringNotNullOrEmpty(widget.question.title)) ...[
            Text(
              widget.question.title ?? "",
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: context.colors.primary,
              ),
            ),
            SizedBox(height: 20.h),
          ],
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 0.w),
            child: CustomTextField(
              hint: "Text Area....",
              contentPaddingHorizontal: 20.w,
              contentPaddingVertical: 10.w,
              textInputAction: TextInputAction.send,
              onChanged: (value) {
                if (_debounce?.isActive ?? false) _debounce?.cancel();
                _debounce = Timer(const Duration(seconds: 1), () {
                  if (stringNotNullOrEmpty(value)) {
                    context.read<DiaryBloc>().add(AddQuetsion(
                        question: InfoQuestion(id: widget.question.id, info: value),
                        categoryId: widget.question.categoryId));
                  }
                });
              },
              controller: controller,
              backgroundColor: const Color(0xfff6f6f6),
              maxLines: 5,
            ),
          ),
        ],
      ),
    );
  }
}


class EmailItem extends StatefulWidget {
  final QuestionTemplate question;
  const EmailItem({super.key, required this.question});

  @override
  State<EmailItem> createState() => _EmailItemState();
}

class _EmailItemState extends State<EmailItem> {
  Timer? _debounce;
  TextEditingController controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  dispose() {
    _debounce?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.white, width: 1.w),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (stringNotNullOrEmpty(widget.question.title)) ...[
              Text(
                widget.question.title ?? "",
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: context.colors.primary,
                ),
              ),
              SizedBox(height: 20.h),
            ],
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 0.w),
              child: CustomTextField(
                hint: "Enter your email...",
                contentPaddingHorizontal: 20.w,
                contentPaddingVertical: 10.w,
                textInputAction: TextInputAction.send,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (!stringNotNullOrEmpty(value)) {
                    return "Email is required";
                  }
                  if (!isValidEmail(value)) {
                    return "Invalid email format";
                  }
                  return null;
                },
                onSubmit: (value) {
                  if (_debounce?.isActive ?? false) _debounce?.cancel();
                  _debounce = Timer(const Duration(seconds: 1), () {
                    if (stringNotNullOrEmpty(value)) {
                      context.read<DiaryBloc>().add(AddQuetsion(
                          question: InfoQuestion(id: widget.question.id, info: value),
                          categoryId: widget.question.categoryId));
                    }
                  });
                },
                onChanged: (value) {
                  if (_debounce?.isActive ?? false) _debounce?.cancel();
                  _debounce = Timer(const Duration(seconds: 1), () {
                    if (_formKey.currentState?.validate() ?? false) {
                      context.read<DiaryBloc>().add(AddQuetsion(
                          question: InfoQuestion(id: widget.question.id, info: value),
                          categoryId: widget.question.categoryId));
                    }
                  });
                },
                controller: controller,
                backgroundColor: const Color(0xfff6f6f6),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool isValidEmail(String? email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email ?? "");
  }
}