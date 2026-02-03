import 'dart:io';

import 'package:escola/core/components/buttons/custom_button.dart';
import 'package:escola/core/components/fields/custom_text_field.dart';
import 'package:escola/core/components/loading/loading_linear.dart';
import 'package:escola/core/config/widgets/config_builder.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/models/generic_state.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/features/settings/medicines_professors/widgets/medicine_request/bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BottomSheetWidget extends StatefulWidget {
  const BottomSheetWidget({
    super.key,
    required this.bloc,
    required this.id,
  });

  final String id;
  final MedReqBloc bloc;

  @override
  State<BottomSheetWidget> createState() => _BottomSheetWidgetState();
}

class _BottomSheetWidgetState extends State<BottomSheetWidget> {
  late final TextEditingController reasonController;
  late final ValueNotifier<List<File>> filesController;
  final formKey = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
    reasonController = TextEditingController();
    filesController = ValueNotifier([]);
  }

  @override
  void dispose() {
    filesController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
          color: context.colors.background,
          padding: EdgeInsets.symmetric(vertical: 30.csh, horizontal: 25.csw),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                SizedBox(
                  width: double.maxFinite,
                  child: Text(
                    LocalizationKeys.decline_reason.tr(context),
                    style: TextStyle(
                      color: context.colors.primary,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  height: 32.csh,
                ),
                CustomTextField(
                  hint: LocalizationKeys.write_the_reason.tr(context),
                  hintFontSize: 14.sp,
                  controller: reasonController,
                  backgroundColor: context.colors.scaffold,
                  padding: EdgeInsets.symmetric(horizontal: 20.csw, vertical: 20.csh),
                  hintColor: context.colors.greyDarker,
                  borderRadius: 12.r,
                  validator: (p0) {
                    if (p0 == null || p0.isEmpty) {
                      return LocalizationKeys.this_field_cant_be_empty.tr(context);
                    }
                    return null;
                  },
                  minLines: 4,
                  maxLines: 6,
                ),
                SizedBox(
                  height: 20.csh,
                ),
                // GestureDetector(
                //   onTap: () async {
                //     final res = await pickAttachments(context);
                //     if (validList(res)) {
                //       filesController.value = [...filesController.value, ...res.map((e) => File(e))];
                //     }
                //   },
                //   child: SizedBox(
                //     height: 61.csh,
                //     child: DottedBorder(
                //       color: context.colors.greyLight,
                //       strokeWidth: 1.0,
                //       dashPattern: const [10, 10],
                //       radius: const Radius.circular(10),
                //       borderType: BorderType.RRect,
                //       child: Center(
                //         child: Row(
                //           mainAxisAlignment: MainAxisAlignment.center,
                //           crossAxisAlignment: CrossAxisAlignment.center,
                //           mainAxisSize: MainAxisSize.max,
                //           children: [
                //             SvgPicture.asset(
                //               'assets/icons/attachment.svg',
                //               height: 16.csh,
                //               width: 14.5.csw,
                //             ),
                //             SizedBox(
                //               width: 10.csw,
                //             ),
                //             Text(
                //               LocalizationKeys.attachment.tr(context),
                //               style: TextStyle(
                //                 fontSize: 16.sp,
                //                 fontWeight: FontWeight.w500,
                //                 color: context.colors.primaryLight,
                //               ),
                //             ),
                //           ],
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
                // ValueListenableBuilder(
                //   valueListenable: filesController,
                //   builder: (context, value, child) => !validList(filesController.value)
                //       ? const SizedBox()
                //       : Padding(
                //           padding: EdgeInsets.only(top: 15.csh),
                //           child: SizedBox(
                //             height: 70.csh,
                //             child: ListView.separated(
                //               scrollDirection: Axis.horizontal,
                //               itemCount: filesController.value.length,
                //               separatorBuilder: (context, index) => SizedBox(width: 5.csw),
                //               itemBuilder: (context, index) => GestureDetector(
                //                 onTap: () => removeFile(index),
                //                 child: FileItem(file: filesController.value[index]),
                //               ),
                //             ),
                //           ),
                //         ),
                // ),
                SizedBox(
                  height: 20.csh,
                ),
                BlocBuilder<MedReqBloc, GenericState>(
                  bloc: widget.bloc,
                  buildWhen: compareStates([
                    (s) => s.loading,
                  ]),
                  builder: (context, state) => state.loading
                      ? const LoadingLinear()
                      : CustomButton(
                          title: LocalizationKeys.save.tr(context),
                          onTap: () {
                            if (formKey.currentState?.validate() ?? false) {
                              widget.bloc.rejectRequest(widget.id, reasonController.text, []);
                              Navigator.of(context).maybePop(true);
                            }
                            //todo
                            // widget.bloc.rejectRequest(widget.id, reasonController.text, []);
                            // Navigator.of(context).maybePop(true);
                          },
                          horizontalPadding: 0,
                          textVerticalPadding: 20,
                        ),
                )
              ],
            ),
          )),
    );
  }

  removeFile(int index) async {
    final files = [...filesController.value];
    if (files.length > index) {
      files.removeAt(index);
      filesController.value = files;
    }
  }
}
