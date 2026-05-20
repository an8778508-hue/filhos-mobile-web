import 'package:escola/core/components/buttons/custom_button.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/features/diary/models/school_item.dart';
import 'package:escola/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UpdateQuestionsButton extends StatelessWidget {
  final SchoolItem item;
  const UpdateQuestionsButton({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DiaryBloc, DiaryState>(
      listener: (context, state) {
        if (state is SendQuestionsSucceed) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: context.colors.success,
              content:
                  Text(LocalizationKeys.updated_successfully.tr(context))));
          final nav = Navigator.of(context);
          Future.delayed(const Duration(seconds: 1), () {
            nav.pop();
          });
        } else if (state is SendQuestionsError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Colors.red,
              content: Text(
                state.failure.message,
              )));
        }
      },
      builder: (context, state) {
        final categories = context.read<DiaryBloc>().categoriesToSend;
        final bool isDisabled = categories.isEmpty;
        return CustomButton(
          title: LocalizationKeys.update.tr(context),
          isDisabled: isDisabled,
          isLoading: false,
          onTap: () {
            context.read<DiaryBloc>().add(SendQuestionsToApi(item: item));
          },
        );
      },
    );
  }
}
