import 'package:escola/core/components/buttons/custom_button.dart';
import 'package:escola/core/components/dialogs/dialogs_functions.dart';
import 'package:escola/core/components/loading/loading.dart';
import 'package:escola/core/components/pagination.dart';
import 'package:escola/core/components/snack.dart';
import 'package:escola/core/components/widgets/app_bar.dart';
import 'package:escola/core/config/widgets/config_builder.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/add_form/add_form_screen.dart';
import 'package:escola/features/add_medicine/add_medicine_screen.dart';
import 'package:escola/features/settings/medicines/bloc/medicines_bloc.dart';
import 'package:escola/features/settings/medicines/bloc/medicines_events.dart';
import 'package:escola/features/settings/medicines/bloc/medicines_states.dart';
import 'package:escola/features/settings/medicines/widgets/empty_medicine.dart';
import 'package:escola/features/settings/medicines/widgets/medicine_body.dart';
import 'package:escola/features/settings/medicines/widgets/medicine_header_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MedicinesScreen extends StatelessWidget {
  const MedicinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
        title: LocalizationKeys.medicines.tr(context),
      ),
      backgroundColor: context.colors.scaffold,
      body: BlocProvider<MedicinesBloc>(
        create: (BuildContext context) => di<MedicinesBloc>()..add(const FetchMedicines()),
        child: MultiBlocListener(
          listeners: [
            BlocListener<MedicinesBloc, MedicinesStates>(
              listenWhen: compareStates([(s) => s.deleteState.success]),
              listener: (context, state) {
                if (state.deleteState.success) {
                  Snack.show(context, LocalizationKeys.success_action.tr(context), true);
                }
              },
            ),
            BlocListener<MedicinesBloc, MedicinesStates>(
              listenWhen: compareStates([(s) => s.deleteState.failure]),
              listener: (context, state) {
                if (validString(state.deleteState.failure?.message)) {
                  Snack.show(context, state.deleteState.failure!.message, false);
                }
              },
            ),
          ],
          child: BlocSelector<MedicinesBloc, MedicinesStates, bool>(
            selector: (state) => state.deleteState.loading,
            builder: (context, loading) => loading
                ? const Center(child: Loading())
                : Column(
                    children: [
                      SizedBox(
                        height: 15.h,
                      ),
                      Expanded(
                        child: BlocSelector<MedicinesBloc, MedicinesStates, AllMedicinesState>(
                          selector: (state) => state.allMedicinesState,
                          builder: (context, state) {
                            final medicines = state.data;
                            final loading = state.loading;
                            if (loading) {
                              return const Center(child: Loading());
                            }
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (medicines.isNotEmpty)
                                  Expanded(
                                    child: Pagination(
                                      onLoadMore: () {
                                        // BlocProvider.of<MedicinesBloc>(context).add(const LoadMoreMedicines());
                                      },
                                      noMore: () => state.noMore,
                                      child: RefreshIndicator(
                                        onRefresh: () async {
                                          BlocProvider.of<MedicinesBloc>(context).add(const FetchMedicines());
                                        },
                                        child: CustomScrollView(
                                          slivers: [
                                            SliverPadding(
                                              padding: EdgeInsets.only(bottom: 20.h),
                                              sliver: SliverList(
                                                delegate: SliverChildBuilderDelegate(
                                                  childCount: medicines.length,
                                                      (context, index) {
                                                    final med = medicines[index];
                                                    if(med.medicines.isEmpty){
                                                      return SizedBox();
                                                    }
                                                    final w = Column(
                                                      children: [
                                                        MedicineHeaderWidget(
                                                          imageUrl: med.userModel?.image ?? '',
                                                          title: med.userModel?.name ?? '',
                                                          subTitle: med.userModel?.classRoom ?? '',
                                                        ),
                                                        for (int i = 0; i < med.medicines.length; i++)
                                                          MedicineBody(
                                                            title: med.medicines[i].name,
                                                            dose: med.medicines[i].potion,
                                                            note: med.medicines[i].details,
                                                            imageUrl: (med.medicines[i].image??[]).map((e) => e.url).toList(),
                                                            status: med.medicines[i].status,
                                                            reason: med.medicines[i].notes,
                                                            model: med.medicines[i],
                                                            onEdit: () async {
                                                              final bloc = BlocProvider.of<MedicinesBloc>(context);
                                                              final b =
                                                                  await Navigator.of(context).push(MaterialPageRoute(
                                                                      builder: (context) => AddMedicineScreen(
                                                                            type: AddFormType.medicine,
                                                                            id: med.medicines[i].id,
                                                                        medicineModel:med ,
                                                                        medicineBodyModel:med.medicines[i] ,
                                                                          )));
                                                              if (b == true) {
                                                                bloc.add(const FetchMedicines());
                                                              }
                                                            },
                                                            onDelete: () async {
                                                              final confirm = await confirmDialog(
                                                                  context: context,
                                                                  titleKey: LocalizationKeys.delete_medicine_title,
                                                                  bodyKey: LocalizationKeys.delete_medicine_content);
                                                              if (confirm == true) {
                                                                if (context.mounted) {
                                                                  BlocProvider.of<MedicinesBloc>(context)
                                                                      .add(DeleteMedicine(med.medicines[i].id));
                                                                }
                                                              }
                                                            },
                                                          ),
                                                      ],
                                                    );

                                                    return Column(
                                                      children: [
                                                        if (index > 0) SizedBox(height: 18.h),
                                                        w,
                                                      ],
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                            if (false)
                                              SliverToBoxAdapter(
                                                child: Center(
                                                  child: state.noMore ? const NoMore() : const LoadingMore(),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                if (medicines.isNotEmpty)
                                  Padding(
                                      padding: EdgeInsets.symmetric(vertical: 20.csh),
                                      child: CustomButton(
                                        title: LocalizationKeys.add_medicine.tr(context),
                                        onTap: () async {
                                          final bloc = BlocProvider.of<MedicinesBloc>(context);
                                          final b = await Navigator.of(context).push(MaterialPageRoute(
                                              builder: (context) =>
                                                  const AddMedicineScreen(type: AddFormType.medicine)));
                                          if (b == true) {
                                            bloc.add(const FetchMedicines());
                                          }
                                        },
                                      )),
                                if (medicines.isEmpty) const EmptyMedicine(),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
