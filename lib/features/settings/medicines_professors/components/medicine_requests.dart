import 'package:escola/core/components/loading/loading.dart';
import 'package:escola/core/components/snack.dart';
import 'package:escola/core/config/widgets/config_builder.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/models/generic_state.dart';
import 'package:escola/core/utils/alarm_manager/alarm_manager.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/settings/medicines/models/medicine_model.dart';
import 'package:escola/features/settings/medicines/widgets/bottom_sheet_widget.dart';
import 'package:escola/features/settings/medicines/widgets/medicine_body.dart';
import 'package:escola/features/settings/medicines/widgets/medicine_header_widget.dart';
import 'package:escola/features/settings/medicines_professors/bloc/medicines_professors_bloc.dart';
import 'package:escola/features/settings/medicines_professors/bloc/medicines_professors_states.dart';
import 'package:escola/features/settings/medicines_professors/widgets/medicine_request/bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../widgets/empty_medicines.dart';

class MedicinesRequestsPage extends StatefulWidget {
  const MedicinesRequestsPage({
    super.key,
  });

  @override
  State<MedicinesRequestsPage> createState() => _MedicinesRequestsPageState();
}

class _MedicinesRequestsPageState extends State<MedicinesRequestsPage> with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    super.initState();
    BlocProvider.of<MedicinesProfessorsBloc>(context).loadRequests();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: () => BlocProvider.of<MedicinesProfessorsBloc>(context).loadRequests(RequestType.reload),
      child: BlocSelector<MedicinesProfessorsBloc, MedicinesProfessorsStates, GenericListState<MedicineModel>>(
        selector: (state) => state.requestsState,
        builder: (context, state) {
          final medicines = state.data;
          final loading = state.loading;
          if (loading) {
            return const Center(
              child: Loading(),
            );
          }
          return !validList(medicines)
              ? const EmptyMedicines()
              : ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 17.csw, vertical: 20.h),
                  itemCount: medicines.length,
                  separatorBuilder: (context, index) => SizedBox(height: 15.h),
                  itemBuilder: (context, index) {
                    final med = medicines[index];
                    return ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(15.r)),
                      child: Column(
                        children: [
                          MedicineHeaderWidget(
                            imageUrl: med.userModel?.image ?? '',
                            title: med.userModel?.name ?? '',
                            subTitle: med.userModel?.name ?? '',
                          ),
                          for (int i = 0; i < med.medicines.length; i++)
                            BlocProvider(
                              create: (context) => MedReqBloc(di()),
                              child: Builder(
                                builder: (context) => BlocListener<MedReqBloc, GenericState>(
                                  listenWhen: compareStates([
                                    (s) => s.success,
                                  ]),
                                  listener: (BuildContext context, state) {
                                    if (state.success) {
                                      Snack.show(context, LocalizationKeys.success_action.tr(context), true);
                                      getAlarms(context);
                                      BlocProvider.of<MedicinesProfessorsBloc>(context).loadReminders(RequestType.reload);
                                      BlocProvider.of<MedicinesProfessorsBloc>(context).loadRequests(RequestType.reload);
                                      BlocProvider.of<MedicinesProfessorsBloc>(context).loadHistory(RequestType.reload);
                                    }
                                  },
                                  child: BlocSelector<MedReqBloc, GenericState, bool>(
                                    selector: (state) => state.loading,
                                    builder: (context, loading) => MedicineBody(
                                      title: med.medicines[i].name,
                                      dose: med.medicines[i].potion,
                                      note: med.medicines[i].details,
                                      imageUrl: (med.medicines[i].image??[]).map((e) => e.url).toList(),
                                      loading: loading,
                                      status: med.medicines[i].status,
                                      reason: med.medicines[i].notes,
                                      model: med.medicines[i],
                                      onEdit: () {},
                                      onDelete: () {},
                                      onApprove: () {
                                        // final raw = med.medicines[i].raw;
                                        //
                                        // // month, week, day
                                        // final periodType = raw['day'].toString();
                                        // final int daysNumber;
                                        // switch (periodType) {
                                        //   case '1':
                                        //     daysNumber = 30;
                                        //     break;
                                        //   case '2':
                                        //     daysNumber = 7;
                                        //     break;
                                        //   case '3':
                                        //     daysNumber = 1;
                                        //     break;
                                        //   default:
                                        //     daysNumber = 0;
                                        //     return;
                                        // }
                                        // if (daysNumber == 0) {
                                        //   return;
                                        // }
                                        // final period = raw['period_of_time'].toString();
                                        // final days = (daysNumber * (double.tryParse(period) ?? 0)).round();
                                        // if (days == 0) {
                                        //   return;
                                        // }
                                        //
                                        // // night, midday, morning
                                        // final timeTypes = raw['tempo'];
                                        // if (!validList(timeTypes)) {
                                        //   return;
                                        // }
                                        // final List<String> times = [];
                                        // for (final timeType in timeTypes) {
                                        //   final String time;
                                        //   switch (timeType.toString()) {
                                        //     case '1':
                                        //       time = '15:00';
                                        //       break;
                                        //     case '2':
                                        //       time = '12:00';
                                        //       break;
                                        //     case '3':
                                        //       time = '09:00';
                                        //       break;
                                        //     default:
                                        //       time = '';
                                        //       return;
                                        //   }
                                        //   times.add(time);
                                        // }
                                        //
                                        // if (!validList(times)) {
                                        //   return;
                                        // }

                                        BlocProvider.of<MedReqBloc>(context).acceptRequest(
                                          med.medicines[i].id,
                                        );
                                      },
                                      onDecline: () async {
                                        final b = await showModalBottomSheet(
                                          backgroundColor: context.colors.background,
                                          context: context,
                                          clipBehavior: Clip.antiAlias,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(12.r),
                                            ),
                                          ),
                                          useSafeArea: false,
                                          isScrollControlled: true,
                                          builder: (BuildContext _) => BottomSheetWidget(
                                            bloc: BlocProvider.of<MedReqBloc>(context),
                                            id: med.medicines[i].childMedicineId,
                                          ),
                                        );
                                        if (b == true) {
                                          if (mounted) {
                                            BlocProvider.of<MedicinesProfessorsBloc>(context).loadReminders(RequestType.reload);
                                            BlocProvider.of<MedicinesProfessorsBloc>(context).loadRequests(RequestType.reload);
                                            BlocProvider.of<MedicinesProfessorsBloc>(context).loadHistory(RequestType.reload);
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
