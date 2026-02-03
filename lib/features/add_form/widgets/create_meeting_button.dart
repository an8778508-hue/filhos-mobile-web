import 'package:escola/core/components/fields/error_field.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/add_form/bloc/add_form_bloc.dart';
import 'package:escola/features/add_form/models/create_meeting_button_model.dart';
import 'package:escola/features/add_form/utils/utils.dart';
import 'package:escola/features/add_form/widgets/forms.dart';
import 'package:escola/shared/assets/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../core/components/my_icon.dart';
import '../bloc/add_form_state.dart';

class CreateMeetingButton extends StatefulWidget {
  const CreateMeetingButton({
    super.key,
    required this.model,
  });

  final CreateMeetingButtonModel model;

  @override
  State<CreateMeetingButton> createState() => _CreateMeetingButtonState();
}

class _CreateMeetingButtonState extends State<CreateMeetingButton> {
  late final ValueNotifier<bool> showCreateMeetingForm;
  late final TextEditingController textController;

  @override
  void initState() {
    super.initState();
    showCreateMeetingForm = ValueNotifier(false);
    showCreateMeetingForm.addListener(() {
      if(showCreateMeetingForm.value != true){
        textController.clear();
      }
    });
    textController = TextEditingController();
    textController.addListener(() {
      final text = textController.text;
      AddFormBloc.get(context).updateForm(widget.model, text);
    });
  }

  @override
  void dispose() {
    showCreateMeetingForm.dispose();
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddFormBloc, AddFormState>(
      listenWhen: updateWhen(widget.model),
      listener: (context, state) {
        final formData = validateString(getData(state, widget.model));
        if (validString(formData) && !showCreateMeetingForm.value) {
          showCreateMeetingForm.value = true;
        }
      },
      child: ValueListenableBuilder(
        valueListenable: showCreateMeetingForm,
        builder: (context, value, child) => value
            ? CreateMeetingForm(
                textController: textController,
                model: widget.model,
                onCancelled: () {
                  showCreateMeetingForm.value = false;
                },
              )
            : child!,
        child: Column(
          children: [
            Material(
              borderRadius: BorderRadius.circular(10.r),
              color: context.colors.primaryBackground,
              child: InkWell(
                borderRadius: BorderRadius.circular(10.r),
                onTap: () {
                  showCreateMeetingForm.value = true;
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 13.h,
                    horizontal: 18.w,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: MyIcon(
                          Assets.icons.googleMeetIcon.path,
                          size: 40.sp,
                        ),
                      ),
                      Text(
                        widget.model.label?.tr(context) ?? '',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w400,
                          color: context.colors.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (widget.model.required)
              FormField(
                validator: (value) {
                  if (validString(textController.text)) {
                    return null;
                  }
                  return LocalizationKeys.this_field_cant_be_empty.tr(context);
                },
                builder: (field) => field.hasError && validString(field.errorText)
                    ? ErrorField(
                        text: field.errorText!,
                      )
                    : const SizedBox(),
              ),
          ],
        ),
      ),
    );
  }
}

class CreateMeetingForm extends StatelessWidget {
  const CreateMeetingForm({
    super.key,
    required this.model,
    required this.onCancelled,
    required this.textController,
  });

  final CreateMeetingButtonModel model;
  final VoidCallback onCancelled;
  final TextEditingController textController;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddFormBloc, AddFormState>(
      listenWhen: updateWhen(model),
      listener: (context, state) {
        final data = textController.text;
        final formData = validateString(getData(state, model));
        if (validString(formData) && data != formData) {
          textController.text = formData;
        }
      },
      child: FormCard(
        forceNested: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0.w).add(EdgeInsets.only(top: 15.h)),
              child: FormCard(
                forceNested: true,
                child: TextFormField(
                  controller: textController,
                  onTapOutside: (event) => FocusScope.of(context).unfocus(),
                  style: TextStyle(
                    color: context.colors.textColor,
                    fontWeight: FontWeight.w400,
                    fontSize: 14.sp,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: model.hint?.tr(context),
                    hintStyle: TextStyle(
                      color: context.colors.greyDarker,
                      fontWeight: FontWeight.w400,
                      fontSize: 14.sp,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 22.w,
                      vertical: 18.h,
                    ),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    launchUrlString('http://meet.google.com/new');
                  },
                  child: Padding(
                    padding: EdgeInsets.all(15.w),
                    child: Text(
                      LocalizationKeys.create_meeting.tr(context),
                      style: TextStyle(
                        color: context.colors.primary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    onCancelled();
                  },
                  child: Padding(
                    padding: EdgeInsets.all(15.w),
                    child: Text(
                      LocalizationKeys.cancel.tr(context),
                      style: TextStyle(
                        color: context.colors.primary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
