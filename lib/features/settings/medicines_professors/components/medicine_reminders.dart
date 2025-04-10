import 'package:escola/core/components/icons/avatar.dart';
import 'package:escola/core/components/loading/loading.dart';
import 'package:escola/core/config/widgets/config_builder.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/models/generic_state.dart';
import 'package:escola/core/utils/alarm_manager/alarm_manager.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/settings/medicines_professors/bloc/medicines_professors_bloc.dart';
import 'package:escola/features/settings/medicines_professors/bloc/medicines_professors_states.dart';
import 'package:escola/features/settings/medicines_professors/widgets/prescription/bloc/bloc.dart';
import 'package:escola/features/settings/medicines_professors/widgets/prescription/medicine_prescription_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:separated_column/separated_column.dart';
import 'package:separated_row/separated_row.dart';

import '../models/medicine_prescription_model.dart';
import '../widgets/empty_medicines.dart';

class MedicinesRemindersPage extends StatefulWidget {
  const MedicinesRemindersPage({
    super.key,
  });

  @override
  State<MedicinesRemindersPage> createState() => _MedicinesRemindersPageState();
}

class _MedicinesRemindersPageState extends State<MedicinesRemindersPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    BlocProvider.of<MedicinesProfessorsBloc>(context).loadReminders();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: () => BlocProvider.of<MedicinesProfessorsBloc>(context).loadReminders(RequestType.reload),
      child: BlocSelector<MedicinesProfessorsBloc, MedicinesProfessorsStates, GenericListState<MedicinePrescriptionModel>>(
        selector: (state) => state.reminderState,
        builder: (context, state) {
          final data = state.data;
          final loading = state.loading;
          if (loading) {
            return const Center(
              child: Loading(),
            );
          }
          return !validList(data)
              ? const EmptyMedicines()
              : ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 17.csw, vertical: 20.h),
                  itemCount: data.length,
                  separatorBuilder: (context, index) => SizedBox(height: 15.h),
                  itemBuilder: (context, index) {
                    final med = data[index];
                    final child = med.child;
                    final feed = med.feed;
                    return ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(15.r)),
                      child: Container(
                        color: context.colors.background,
                        child: Column(
                          children: [
                            if (child != null)
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20.0.w,
                                  vertical: 20.h,
                                ),
                                child: SeparatedRow(
                                  separatorBuilder: (context, index) => SizedBox(width: 16.w),
                                  children: [
                                    if (validString(child.avatar))
                                      Avatar(
                                        avatar: child.avatar,
                                        size: 60.w,
                                        isChild: true,
                                      ),
                                    if (validString(child.name) || validString(child.classRoom))
                                      SeparatedColumn(
                                        separatorBuilder: (context, index) => SizedBox(height: 8.h),
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (validString(child.name))
                                            Text(
                                              child.name!,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20.sp,
                                                color: context.colors.textColor,
                                              ),
                                            ),
                                          if (validString(child.classRoom))
                                            Text(
                                              child.classRoom!,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w400,
                                                fontSize: 16.sp,
                                                color: context.colors.textColor,
                                              ),
                                            ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            if (validList(feed))
                              SeparatedColumn(
                                separatorBuilder: (context, index) => Container(
                                  color: context.colors.disabled,
                                  height: 1,
                                ),
                                children: [
                                  ...feed.map(
                                    (item) {
                                      return BlocProvider<MedPresBloc>(
                                        key: ValueKey(item.id),
                                        create: (context) => MedPresBloc(di()),
                                        child: Builder(
                                          builder: (context) => GestureDetector(
                                            onTap: () => BlocProvider.of<MedPresBloc>(context).check(item),
                                            child: BlocConsumer<MedPresBloc, GenericState>(
                                              listenWhen: compareStates([
                                                (s) => s.success,
                                              ]),
                                              listener: (context, state) {
                                                if (state.success) {
                                                  BlocProvider.of<MedicinesProfessorsBloc>(context).loadReminders(RequestType.reload, true);
                                                  BlocProvider.of<MedicinesProfessorsBloc>(context).loadHistory(RequestType.reload);
                                                  di<AlarmManager>().removeAlarm(id: item.id);
                                                }
                                              },
                                              builder: (context, state) => MedicinePrescriptionItem(
                                                model: item,
                                                checked: state.success,
                                                loading: state.loading,
                                                error: state.failure?.message,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
        },
      ),
    );
  }
}
