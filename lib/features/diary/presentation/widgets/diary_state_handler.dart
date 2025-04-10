import 'package:escola/core/components/widgets/error_widget.dart';
import 'package:escola/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:escola/features/diary/presentation/widgets/diary_activites.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:escola/core/components/loading/loading.dart';

class DiaryStateHandler extends StatelessWidget {
  final bool hasChild;
  const DiaryStateHandler({super.key, required this.hasChild});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiaryBloc, DiaryState>(
      builder: (context, state) {
        if (state is DiaryActivitiesLoading) {
          return Column(
            children: [
              SizedBox(height: 100.h),
              const Loading(),
            ],
          );
        } else if (state is DiaryActivitiesLoaded) {
          return DiaryActivities(hasChild: hasChild);
        } else if (state is DiaryActivitiesError) {
          return Column(
            children: [
              SizedBox(height: 100.h),
              Center(
                child: ErrorScreen(
                  errorText: state.failure.message,
                  onRetry: () {
                    context.read<DiaryBloc>().add(GetDiaryActivities(
                        date: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)));
                  },
                ),
              ),
            ],
          );
        }
        return const SizedBox();
      },
    );
  }
}
