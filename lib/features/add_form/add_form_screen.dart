import 'package:escola/core/components/loading/loading.dart';
import 'package:escola/core/components/loading/loading_overlay.dart';
import 'package:escola/core/components/snack.dart';
import 'package:escola/core/components/widgets/app_bar.dart';
import 'package:escola/core/config/widgets/config_builder.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/event_bus.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/safe_x.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/add_form/bloc/add_form_bloc.dart';
import 'package:escola/features/add_form/bloc/add_form_state.dart';
import 'package:escola/features/add_form/models/add_form_model.dart';
import 'package:escola/features/add_form/models/attachments_model.dart';
import 'package:escola/features/add_form/models/attendants_selection_model.dart';
import 'package:escola/features/add_form/models/comments_model.dart';
import 'package:escola/features/add_form/models/counter_model.dart';
import 'package:escola/features/add_form/models/create_meeting_button_model.dart';
import 'package:escola/features/add_form/models/date_picker_model.dart';
import 'package:escola/features/add_form/models/dropdown_model.dart';
import 'package:escola/features/add_form/models/multiselect_model.dart';
import 'package:escola/features/add_form/models/number_model.dart';
import 'package:escola/features/add_form/models/period_of_time_model.dart';
import 'package:escola/features/add_form/models/segmented_control_model.dart';
import 'package:escola/features/add_form/models/text_model.dart';
import 'package:escola/features/add_form/models/time_picker_model.dart';
import 'package:escola/features/add_form/models/upload_image_model.dart';
import 'package:escola/features/add_form/widgets/attachments.dart';
import 'package:escola/features/add_form/widgets/attendants_selection_button.dart';
import 'package:escola/features/add_form/widgets/comments.dart';
import 'package:escola/features/add_form/widgets/empty.dart';
import 'package:escola/features/add_form/widgets/number.dart';
import 'package:escola/features/diary/models/school_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:separated_column/separated_column.dart';

import 'add_form_type.dart';
import 'models/collection_model.dart';
import 'models/group_model.dart';
import 'models/params.dart';
import 'models/rich_text_model.dart';
import 'models/text_area_model.dart';
import 'widgets/collection.dart';
import 'widgets/counter.dart';
import 'widgets/create_meeting_button.dart';
import 'widgets/date_picker.dart';
import 'widgets/dropdown.dart';
import 'widgets/forms.dart';
import 'widgets/group.dart';
import 'widgets/multiselect.dart';
import 'widgets/period_of_time.dart';
import 'widgets/rich_text.dart';
import 'widgets/segmented.dart';
import 'widgets/text.dart';
import 'widgets/text_area.dart';
import 'widgets/time_picker.dart';
import 'widgets/upload_image.dart';

export 'add_form_type.dart';

class AddFormScreen extends StatelessWidget {
  const AddFormScreen({
    super.key,
    required this.type,
    this.id,
  });

  final AddFormType type;
  final String? id;

  @override
  Widget build(BuildContext context) {
    return Provider<AddFormType>(
      lazy: false,
      create: (context) => type,
      child: BlocProvider(
        create: (context) => di<AddFormBloc>(instanceName: type.name),
        child: AddFormBody(
          id: id,
          addFormType: type,
        ),
      ),
    );
  }
}

String getScreenName(AddFormType type) {
  switch (type) {
    case AddFormType.medicine:
      return LocalizationKeys.add_now;
    case AddFormType.event:
      return LocalizationKeys.add_event;
    case AddFormType.announcement:
      return LocalizationKeys.add_announcement;
  }
}

String getErrorMessage(AddFormType type) {
  switch (type) {
    case AddFormType.medicine:
      return LocalizationKeys.error_fetch_prescriptions;
    case AddFormType.event:
      return LocalizationKeys.error_fetch_events;
    case AddFormType.announcement:
      return LocalizationKeys.error_fetch_announcements;
  }
}

String getSuccessMessage(AddFormType type) {
  switch (type) {
    case AddFormType.medicine:
      return LocalizationKeys.success_save_prescription;
    case AddFormType.event:
      return LocalizationKeys.success_save_event;
    case AddFormType.announcement:
      return LocalizationKeys.success_save_announcement;
  }
}

class AddFormBody extends StatefulWidget {
  const AddFormBody({
    super.key,
    required this.id,
    required this.addFormType,
  });

  final String? id;
  final AddFormType addFormType;

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
            AddFormBloc.get(context).fetchFields(widget.id);
          } else {
            Navigator.of(context).pop();
          }
        }
      } else {
        AddFormBloc.get(context).fetchFields(widget.id);
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
                    (s) => s.fetchApiState.form,
                  ]),
                  builder: (context, state) {
                    final loading = state.fetchApiState.loading;
                    if (loading) {
                      return const Center(child: Loading());
                    }
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(vertical: 30.csh),
                      child: Builder(builder: (context) {
                        final form = state.fetchApiState.form;
                        final List<FormModel>? fields = form?.fields;
                        if (!validList(fields)) {
                          return const Center(child: EmptyAddForm());
                        }

                        final type = Provider.of<AddFormType>(context);
                        return Form(
                          child: SeparatedColumn(
                            separatorBuilder: (context, index) => SizedBox(height: 20.csh),
                            children: [
                              if (type == AddFormType.event || type == AddFormType.announcement)
                                ValueListenableBuilder(
                                  valueListenable: attendantsController,
                                  builder: (context, value, child) => FormSection(
                                    title: LocalizationKeys.select_attendants.tr(context),
                                    children: [
                                      AttendantsSelectionButton(
                                        controller: attendantsController,
                                      ),
                                    ],
                                  ),
                                ),
                              ...getFields(context, fields!),
                              const ErrorFetchSection(),
                              SaveButton(id: widget.id, addFormType: widget.addFormType,),
                              ErrorSaveSection(type: type),
                            ],
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
              BlocSelector<AddFormBloc, AddFormState, bool>(
                selector: (state) => state.saveApiState.loading,
                builder: (context, loading) => loading
                    ? const LoadingOverlay()
                    : const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<Widget> getFields(BuildContext context, List<FormModel> fields) {
  final form = BlocProvider.of<AddFormBloc>(context, listen: true).state.formState;
  return [
    ...fields.where((field) => validateDependency(field, form.data ?? {})).map(
          (field) => FormSection(
            title: field.title,
            children: [getField(field)],
          ),
        ),
  ];
}

bool validateDependency(FormModel field, Map<FormModel, CreateFormParams> form) {
  final dependency = field.dependency;
  if (dependency != null) {
    final id = dependency.id;
    final value = dependency.value;
    final formId = form.keys.safeFirstWhere((e) => e.id == id);
    if (formId != null && form[formId] != null) {
      if (form[formId]!.value != value) {
        return false;
      }
    } else {
      return false;
    }
  }
  return true;
}

Widget getField(FormModel field) {
   // debugPrint('getField ${field.type}');
   debugPrint('getField ${field.id}');
  switch (field.type) {
    case FormType.counter:
      return CounterWidget(model: field as CounterModel);
    case FormType.dropdown:
      return DropDownWidget(model: field as DropDownModel);
    case FormType.multiselect:
      return MultiSelect(model: field as MultiSelectModel);
    case FormType.attendantsSelection:
      return const SizedBox();
    case FormType.segmented:
      return SegmentedControlWidget(model: field as SegmentedControlModel);
    case FormType.periodOfTime:
      return PeriodOfTimeWidget(model: field as PeriodOfTimeModel);
    case FormType.createMeetingButton:
      return CreateMeetingButton(model: field as CreateMeetingButtonModel);
    case FormType.uploadImage:
      return UploadImageWidget(model: field as UploadImageModel);
    case FormType.attachment:
      return AttachmentsWidget(model: field as AttachmentsModel);
    case FormType.comments:
      return CommentsWidget(model: field as CommentsModel);
    case FormType.text:
      return TextFieldWidget(model: field as TextModel);
    case FormType.number:
      return NumberFormFieldWidget(model: field as NumberModel);
    case FormType.textArea:
      return TextAreaFieldWidget(model: field as TextAreaModel);
    case FormType.richText:
      return RichTextFieldWidget(model: field as RichTextModel);
    case FormType.datePicker:
      return DatePickerWidget(model: field as DatePickerModel);
    case FormType.timePicker:
      return TimePickerWidget(model: field as TimePickerModel);
    case FormType.collection:
      return CollectionWidget(model: field as CollectionFormModel);
    case FormType.group:
      return GroupWidget(model: field as GroupFormModel);
    case FormType.unimplemented:
      return const SizedBox();
  }
}

class SaveButton extends StatelessWidget {
  const SaveButton({
    super.key,
    this.id,
    required this.addFormType,
  });

  final String? id;
  final AddFormType addFormType;

  @override
  Widget build(BuildContext context) {
    // todo
    // final hasErrorFetching = BlocProvider.of<AddFormBloc>(context, listen: true).state.fetchApiState.failure != null;
    // if (hasErrorFetching) {
    //   return const SizedBox();
    // }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 42.csw) + EdgeInsets.only(top: 40.csh),
      child: GestureDetector(
        onTap: () {
          if (Form.of(context).validate()) {
            if(addFormType == AddFormType.medicine){
              AddFormBloc.get(context).saveMedicine(id);
            }else{
            AddFormBloc.get(context).saveForm(id);
            }
          }
        },
        child: Container(
          height: 60.csh,
          decoration: BoxDecoration(
            color: context.colors.primary,
            borderRadius: BorderRadius.circular(200.r),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 20.csw,
          ),
          alignment: Alignment.center,
          child: BlocSelector<AddFormBloc, AddFormState, bool>(
            selector: (state) => state.saveApiState.loading,
            builder: (context, loading) => Text(
                    LocalizationKeys.save.tr(context),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 20.sp,
                      color: context.colors.secondaryTextColor,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class ErrorSaveSection extends StatelessWidget {
  const ErrorSaveSection({super.key, required this.type});

  final AddFormType type;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AddFormBloc, AddFormState, Failure?>(
      selector: (state) => state.saveApiState.failure,
      builder: (context, failure) => failure == null
          ? const SizedBox()
          : Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.csw),
                child: Text(
                  getErrorMessage().tr(context),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: context.colors.error,
                  ),
                ),
              ),
            ),
    );
  }

  String getErrorMessage() {
    switch (type) {
      case AddFormType.medicine:
        return LocalizationKeys.error_save_prescription;
      case AddFormType.event:
        return LocalizationKeys.error_save_event;
      case AddFormType.announcement:
        return LocalizationKeys.error_save_announcement;
    }
  }
}

class ErrorFetchSection extends StatelessWidget {
  const ErrorFetchSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AddFormBloc, AddFormState, Failure?>(
      selector: (state) => state.fetchApiState.failure,
      builder: (context, failure) => failure == null
          ? const SizedBox()
          : Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.csw),
                child: Text(
                  failure.message,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: context.colors.error,
                  ),
                ),
              ),
            ),
    );
  }
}
