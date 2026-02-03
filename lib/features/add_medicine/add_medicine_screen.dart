import 'package:escola/core/components/loading/loading.dart';
import 'package:escola/core/components/loading/loading_overlay.dart';
import 'package:escola/core/components/snack.dart';
import 'package:escola/core/components/widgets/app_bar.dart';
import 'package:escola/core/config/widgets/config_builder.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/event_bus.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/add_form/add_form_screen.dart';
import 'package:escola/features/add_form/bloc/add_form_bloc.dart';
import 'package:escola/features/add_form/bloc/add_form_state.dart';
import 'package:escola/features/add_form/models/add_form_model.dart';
import 'package:escola/features/add_form/models/attendants_selection_model.dart';
import 'package:escola/features/add_form/models/collection_model.dart';
import 'package:escola/features/add_form/models/comments_model.dart';
import 'package:escola/features/add_form/models/counter_model.dart';
import 'package:escola/features/add_form/models/date_picker_model.dart';
import 'package:escola/features/add_form/models/dropdown_model.dart';
import 'package:escola/features/add_form/models/params.dart';
import 'package:escola/features/add_form/models/period_of_time_model.dart';
import 'package:escola/features/add_form/models/segmented_control_model.dart';
import 'package:escola/features/add_form/models/text_model.dart';
import 'package:escola/features/add_form/models/upload_image_model.dart';
import 'package:escola/features/add_form/widgets/attendants_selection_button.dart';
import 'package:escola/features/add_form/widgets/collection.dart';
import 'package:escola/features/add_form/widgets/forms.dart';
import 'package:escola/features/diary/models/school_item.dart';
import 'package:escola/features/settings/medicines/models/medicine_body_model.dart';
import 'package:escola/features/settings/medicines/models/medicine_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:separated_column/separated_column.dart';

class AddMedicineScreen extends StatelessWidget {
  const AddMedicineScreen({
    super.key,
    required this.type,
    this.id,
    this.medicineModel,
    this.medicineBodyModel,
  });

  final AddFormType type;
  final MedicineModel? medicineModel;
  final MedicineBodyModel? medicineBodyModel;
  final String? id;

  @override
  Widget build(BuildContext context) {
    return Provider<AddFormType>(
      lazy: false,
      create: (context) => type,
      child: BlocProvider(
        create: (context) => di<AddFormBloc>(instanceName: type.name),
        child: Builder(
          builder: (context) => BlocProvider.value(
            value: AddFormBloc.get(context),
            child: AddFormBody(
              id: id,
              addFormType: type,
              medicineModel: medicineModel,
              medicineBodyModel: medicineBodyModel,
            ),
          ),
        ),
      ),
    );
  }
}

class AddFormBody extends StatefulWidget {
  const AddFormBody({
    super.key,
    required this.id,
    this.medicineModel,
    this.medicineBodyModel,
    required this.addFormType,
  });

  final String? id;
  final AddFormType addFormType;
  final MedicineModel? medicineModel;
  final MedicineBodyModel? medicineBodyModel;

  @override
  State<AddFormBody> createState() => _AddFormBodyState();
}

class _AddFormBodyState extends State<AddFormBody> {
  late final ValueNotifier<List<SchoolItem>> attendantsController;

  @override
  void initState() {
    super.initState();
    attendantsController = ValueNotifier([]);

    attendantsController.addListener(() {
      final bool all = attendantsController.value.any(
        (element) => element.type == SchoolItemType.all,
      );
      final bool allChildType = attendantsController.value.any(
            (element) => element.type == SchoolItemType.allChildType,
          ) ||
          all;
      final bool allTeachersType = attendantsController.value.any(
            (element) => element.type == SchoolItemType.allTeachersType,
          ) ||
          all;
      AddFormBloc.get(context).updateForm(
        const AttendantsSelectionModel(title: 'attendants', id: 'receivers', dependency: null),
        {
          'children': [...attendantsController.value.where((e) => e.type == SchoolItemType.childType).map((e) => e.id)],
          'teachers': [
            if (allTeachersType)
              "all"
            else
              ...attendantsController.value.where((e) => e.type == SchoolItemType.teacherType).map((e) => e.id)
          ],
          'parents': [
            if (allChildType)
              "all"
            else
              ...attendantsController.value.where((e) => e.type == SchoolItemType.parentType).map((e) => e.id)
          ],
          'class': [...attendantsController.value.where((e) => e.type == SchoolItemType.classType).map((e) => e.id)],
          'levels': [...attendantsController.value.where((e) => e.type == SchoolItemType.level).map((e) => e.id)],
        },
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final type = Provider.of<AddFormType>(context, listen: false);
      if (type == AddFormType.event || type == AddFormType.announcement) {
        final result = await AttendantsSelectionSheet.open(context, initial: [...attendantsController.value]);
        if (mounted) {
          if (validList(result)) {
            attendantsController.value = [...result!];
            AddFormBloc.get(context).fetchAddMedicineData(widget.id);
          } else {
            Navigator.of(context).pop();
          }
        }
      } else {
        AddFormBloc.get(context).fetchAddMedicineData(widget.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final type = Provider.of<AddFormType>(context);
    return MultiBlocListener(
      listeners: [
        BlocListener<AddFormBloc, AddFormState>(
          listenWhen: compareStates([(s) => s.saveApiState.success]),
          listener: (context, state) async {
            if (state.saveApiState.success) {
              Snack.show(context, getSuccessMessage(type).tr(context), true);
              eventBus.fire(EventAdded());
              Navigator.of(context).pop(true);
            }
          },
        ),
      ],
      child: Builder(
        builder: (context) => Scaffold(
          appBar: MyAppBar(
            title: getScreenName(type).tr(context),
          ),
          body: Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async => await AddFormBloc.get(context).fetchFields(widget.id, refresh: true),
                child: BlocBuilder<AddFormBloc, AddFormState>(
                  buildWhen: compareStates([
                    (s) => s.fetchApiState.loading,
                    (s) => s.addMedicineFieldsState.loading,
                    (s) => s.fetchApiState.form,
                    (s) => s.addMedicineChildrenState.loading,
                    (s) => s.addMedicineChildrenState.data,
                    (s) => s.addMedicineFieldsState.data,
                  ]),
                  builder: (context, state) {
                    if(widget.medicineBodyModel?.time != null) {
                      print('_AddFormBodyState.build 1 ${widget.medicineBodyModel!.tempoTimeModels.map((e) => e.id).toList()}');
                    }
                    final Map<FormModel, CreateFormParams> form = state.formState.data ?? {};
                    print(Map.fromEntries(form.entries.where((e) => validateDependency(e.key, form)).map((e) => MapEntry(e.key.id, e.value))));
                    final loading = state.fetchApiState.loading || state.addMedicineChildrenState.loading|| state.addMedicineFieldsState.loading;
                    if (loading) {
                      return const Center(child: Loading());
                    }
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(vertical: 30.csh),
                      child: Builder(
                        builder: (context) {
                          final type = Provider.of<AddFormType>(context);
                          return Form(
                            child: SeparatedColumn(
                              separatorBuilder: (context, index) => SizedBox(height: 20.csh),
                              children: [
                                FormSection(
                                  title: LocalizationKeys.determine_child,
                                  children: [
                                    getField(
                                      DropDownModel(
                                        id: 'child_id',
                                        title: LocalizationKeys.determine_child,
                                        values: state.addMedicineChildrenState.data
                                            .map((e) =>
                                                DropDownValueModel(id: e.id.toString(), title: validateString(e.name)))
                                            .toList(),
                                        hint: LocalizationKeys.determine_child,
                                        required: true,
                                        dependency: null,
                                        initial: widget.medicineModel?.userModel?.id
                                      ),
                                    ),
                                  ],
                                ),
                                FormSection(
                                  title: LocalizationKeys.medicine_name,
                                  children: [
                                    getField(
                                      TextModel(
                                        id: 'name',
                                        title: LocalizationKeys.medicine_name,
                                        initial: widget.medicineBodyModel?.name,
                                        hint: LocalizationKeys.medicine_name,
                                        required: true,
                                        dependency: null,
                                      ),
                                    ),
                                  ],
                                ),
                                FormSection(
                                  title: LocalizationKeys.determine_dose,
                                  children: [
                                    getField(
                                      CounterModel(
                                        id: 'dose',
                                        title: LocalizationKeys.determine_dose,
                                        initial: double.tryParse(widget.medicineBodyModel?.potion??'0.0')??0.0,
                                        min: 0.1,
                                        max: 10,
                                        step: 0.1,
                                        required: true,
                                        dependency: null,
                                      ),
                                    ),
                                  ],
                                ),
                                CollectionWidget(
                                  model: CollectionFormModel(
                                    id: 'fields',
                                    title: '',
                                    dependency: null,
                                    items: [
                                      DropDownModel(
                                        id: 'dose_type_id',
                                        initial: widget.medicineBodyModel?.doseType.id,
                                        title: LocalizationKeys.choose_dose,
                                        hint: LocalizationKeys.please_choose_dose,
                                        values: state.addMedicineFieldsState.doseModels ,
                                        required: true,
                                        dependency: null,
                                      ),
                                      DropDownModel(
                                        id: 'dose_number_id',
                                        initial: widget.medicineBodyModel?.number_of_doses.id,
                                        title: LocalizationKeys.number_of_doses,
                                        hint: LocalizationKeys.select_number,
                                        values: state.addMedicineFieldsState.number_of_dosesModels ,
                                        required: true,
                                        dependency: null,
                                      ),
                                      PeriodOfTimeModel(
                                        id: 'tempo',
                                        initial: [if(widget.medicineBodyModel?.time != null)...widget.medicineBodyModel!.tempoTimeModels.map((e) => e.id)],
                                        title: LocalizationKeys.time,
                                        hint: LocalizationKeys.select_time,
                                        values: state.addMedicineFieldsState.periodOfTimeModels ,
                                        required: true,
                                        dependency: null,
                                      ),
                                      SegmentedControlModel(
                                        id: 'instruction_id',
                                        initial: widget.medicineBodyModel?.instructions.id,
                                        title: LocalizationKeys.instructions,
                                        values: state.addMedicineFieldsState.instructionsModels ,
                                        required: true,
                                        dependency: null,
                                      ),
                                      SegmentedControlModel(
                                        id: 'period_id',
                                        initial: widget.medicineBodyModel?.day.id,
                                        title: LocalizationKeys.hour,
                                        values: state.addMedicineFieldsState.periodModels ,
                                        required: true,
                                        dependency: null,
                                      ),
                                    ],
                                  ),
                                ),
                                FormSection(
                                  title: LocalizationKeys.starting_date,
                                  children: [
                                    getField(
                                      DatePickerModel(
                                        id: 'starting_date',
                                        title: LocalizationKeys.starting_date,
                                        hint: LocalizationKeys.select_date,
                                        initial: widget.medicineBodyModel?.startingDate??DateTime.now().add(const Duration(days: 1)),
                                        required: true,
                                        min: DateTime.now().add(const Duration(days: 1)),
                                        dependency: null,
                                      ),
                                    ),
                                  ],
                                ),
                                FormSection(
                                  title: LocalizationKeys.period_time,
                                  children: [
                                    getField(
                                      CounterModel(
                                        id: 'period_time',
                                        title: LocalizationKeys.period_time,
                                        initial: double.tryParse(widget.medicineBodyModel?.period_of_time??'0.0')??0.0,
                                        min: 1,
                                        max: 10,
                                        step: 1,
                                        required: true,
                                        dependency: null,
                                      ),
                                    ),
                                  ],
                                ),
                                FormSection(
                                  children: [
                                    getField(
                                      UploadImageModel(
                                        id: 'images',
                                        title: LocalizationKeys.period_time,
                                        hint: LocalizationKeys.attach_copy_of_recipe_desc,
                                        label: LocalizationKeys.attach_copy_of_recipe,
                                        required: true,
                                        initial:(widget.medicineBodyModel?.image??[]).map((e) => e).toList(),
                                        dependency: null,
                                      ),
                                    ),
                                    getField(
                                      CommentsModel(
                                        id: 'notes',
                                        title: LocalizationKeys.comments,
                                        label: LocalizationKeys.comments,
                                        required: false,
                                        dependency: null,
                                      ),
                                    ),
                                  ],
                                ),
                                const ErrorFetchSection(),
                                SaveButton(id: widget.id, addFormType: widget.addFormType,),
                                ErrorSaveSection(type: type),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              BlocSelector<AddFormBloc, AddFormState, bool>(
                selector: (state) => state.saveApiState.loading,
                builder: (context, loading) => loading ? const LoadingOverlay() : const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
