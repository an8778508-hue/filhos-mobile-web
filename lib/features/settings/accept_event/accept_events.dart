import 'dart:io';

import 'package:escola/core/attachment_selection/attachment_selection.dart';
import 'package:escola/core/components/buttons/custom_button.dart';
import 'package:escola/core/components/icons/common_image.dart';
import 'package:escola/core/components/loading/loading.dart';
import 'package:escola/core/components/read_more.dart';
import 'package:escola/core/components/text/my_text.dart';
import 'package:escola/core/components/text/text_html.dart';
import 'package:escola/core/components/widgets/app_bar.dart';
import 'package:escola/core/components/widgets/error_widget.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/models/event_for_user_model.dart';
import 'package:escola/core/models/single_event_model.dart';
import 'package:escola/core/user/bloc/user_bloc.dart';
import 'package:escola/core/user/bloc/user_state.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/funuctions/global_functions.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/diary/presentation/widgets/gallery_media/media_gallery.dart';
import 'package:escola/features/settings/accept_event/bloc/single_event_bloc.dart';
import 'package:escola/features/settings/accept_event/bloc/single_event_event.dart';
import 'package:escola/features/settings/accept_event/bloc/single_event_state.dart';
import 'package:escola/features/settings/accept_event/widgets/approval_sheet_widget.dart';
import 'package:escola/features/settings/accept_event/widgets/approved_sheet_widget.dart';
import 'package:escola/features/settings/accept_event/widgets/icon_card_widget.dart';
import 'package:escola/features/settings/accept_event/widgets/paid_or_not_paid_widget.dart';
import 'package:escola/features/settings/accept_event/widgets/show_bottom_sheet.dart';
import 'package:escola/flavors/app_flavors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class AcceptEventScreen extends StatefulWidget {
  final String eventId;

  const AcceptEventScreen({super.key, required this.eventId});

  @override
  State<AcceptEventScreen> createState() => _AcceptEventScreenState();
}

class _AcceptEventScreenState extends State<AcceptEventScreen> {
  final PageController _pageController = PageController();
  late final ValueNotifier<File?> imageController;
  XFile? image;
  int index = 0;

  @override
  void initState() {
    super.initState();
    imageController = ValueNotifier(null);
  }

  @override
  void dispose() {
    imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SingleEventBloc>(
      lazy: false,
      create: (context) => di<SingleEventBloc>()
        ..add(
          FetchSingleEvent(eventId: widget.eventId),
        ),
      child: Scaffold(
        backgroundColor: context.colors.background,
        appBar: MyAppBar(
          title: LocalizationKeys.events.tr(context),
          hasNotification: true,
        ),
        body: Builder(
          builder: (context) => BlocBuilder<SingleEventBloc, SingleEventState>(
            builder: (context, state) {
              switch (state) {
                case SingleEventInitial():
                  return Container();
                case SingleEventLoading():
                  return const Center(child: Loading());
                case SingleEventError():
                  return Center(
                    child: ErrorScreen(
                        errorText: state.failure.message,
                        onRetry: () {
                          BlocProvider.of<SingleEventBloc>(context).add(FetchSingleEvent(eventId: widget.eventId));
                        }),
                  );
                case SingleEventFetchedSuccessfully():
                  final SingleEventModel singleEvent = state.singleEventModel;
                  final EventForUserModel? eventForUserModel = state.singleEventModel.eventForUserModel;
                  final list =
                      singleEvent.listImageUrls.isNotEmpty ? singleEvent.listImageUrls : [singleEvent.image_url];

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 223.csh,
                          child: Stack(
                            children: [
                              SizedBox(
                                height: 223.csh,
                                child: Stack(
                                  children: [
                                    PageView.builder(
                                        controller: _pageController,
                                        onPageChanged: (value) {
                                          setState(() {
                                            index = value;
                                          });
                                        },
                                        itemCount: list.length,
                                        itemBuilder: (context, index) {
                                          return GestureDetector(
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) => Dialog(
                                                  insetPadding: EdgeInsets.zero,
                                                  child: MediaGallery(media: list),
                                                ),
                                              );
                                            },
                                            child: Padding(
                                              padding: validString(list[index])
                                                  ? EdgeInsets.zero
                                                  : EdgeInsets.symmetric(vertical: 40.h),
                                              child: CommonImage(
                                                imageUrl: validateString(list[index], assetsPath('default_logo')),
                                                fit: validString(list[index]) ? BoxFit.cover : BoxFit.contain,
                                              ),
                                            ),
                                          );
                                        }),
                                    if (list.length > 1)
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 10.csw),
                                        child: Align(
                                          alignment: Alignment.center,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                                            children: [
                                              IconButton(
                                                alignment: AlignmentDirectional.center,
                                                icon: Stack(
                                                  alignment: AlignmentDirectional.center,
                                                  children: [
                                                    Container(
                                                      height: 40.h,
                                                      width: 40.h,
                                                      alignment: AlignmentDirectional.center,
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(100.r),
                                                        color: context.colors.scaffold,
                                                      ),
                                                    ),
                                                    const Icon(Icons.arrow_back_ios_rounded),
                                                  ],
                                                ),
                                                onPressed: (index != 0)
                                                    ? () {
                                                        _pageController.previousPage(
                                                          duration: const Duration(milliseconds: 300),
                                                          curve: Curves.easeInOut,
                                                        );
                                                      }
                                                    : null,
                                                iconSize: 18.sp,
                                              ),
                                              const Spacer(),
                                              IconButton(
                                                alignment: AlignmentDirectional.center,
                                                icon: Stack(
                                                  alignment: AlignmentDirectional.center,
                                                  children: [
                                                    Container(
                                                      height: 40.h,
                                                      width: 40.h,
                                                      alignment: AlignmentDirectional.center,
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(100.r),
                                                        color: context.colors.scaffold,
                                                      ),
                                                    ),
                                                    const Icon(Icons.arrow_forward_ios_rounded),
                                                  ],
                                                ),
                                                onPressed: (index != list.length - 1)
                                                    ? () {
                                                        _pageController.nextPage(
                                                          duration: const Duration(milliseconds: 300),
                                                          curve: Curves.easeInOut,
                                                        );
                                                      }
                                                    : null,
                                                iconSize: 18.sp,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 25.csw, vertical: 24.csh),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (singleEvent.title != '')
                                CustomSelectableText(
                                  singleEvent.title,
                                  textAlign: TextAlign.start,
                                  style: TextStyle(fontSize: 30.sp, fontWeight: FontWeight.bold),
                                ),
                              if (context.isProfessors) SizedBox(height: 11.csh),
                              if (singleEvent.tags != null && singleEvent.tags!.isNotEmpty)
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: singleEvent.tags!.map((tag) {
                                    return Chip(
                                      label: Text(
                                        tag?.name ?? '',
                                        style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w500,
                                            color: context.colors.primary),
                                      ),
                                      backgroundColor: context.colors.primaryBackground,
                                    );
                                  }).toList(),
                                ),
                              SizedBox(height: 14.csh),
                              if (validString(singleEvent.description))
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final style = TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w400,
                                      color: context.colors.greyDarker,
                                    );
                                    if (getTextSize(
                                          context,
                                          removeHtml(singleEvent.description) ?? '',
                                          style,
                                          constraints,
                                        ).height <
                                        200) {
                                      return TextHtml(
                                        singleEvent.description ?? '', // testJson,
                                        textAlign: TextAlign.start,
                                        style: style,
                                      );
                                    } else {
                                      return ReadMoreBySize(
                                        builder: (more) => TextHtml(
                                          singleEvent.description ?? '', // testJson,
                                          textAlign: TextAlign.start,
                                          style: style,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              SizedBox(height: 30.csh),
                              Row(
                                children: [
                                  if (!(singleEvent.startDate == null && singleEvent.endDate == null))
                                    const IconCardWidget(
                                      icon: FontAwesomeIcons.solidCalendar,
                                    ),
                                  SizedBox(width: 15.csh),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (singleEvent.startDate != null)
                                        Text(
                                          () {
                                            bool isSameDateDay =
                                                isSameDay(time1: singleEvent.startDate!, time2: singleEvent.endDate!);
                                            return isSameDateDay;
                                          }()
                                              ? DateFormat('dd MMM,yyyy').format(singleEvent.startDate!)
                                              : DateFormat('dd MMM,yyyy - hh:mm a').format(singleEvent.startDate!),
                                          textAlign: TextAlign.start,
                                          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w500),
                                        ),
                                      SizedBox(height: 5.csh),
                                      if (singleEvent.endDate != null)
                                        Text(
                                          () {
                                            bool isSameDateDay =
                                                isSameDay(time1: singleEvent.startDate!, time2: singleEvent.endDate!);
                                            return isSameDateDay;
                                          }()
                                              ? "${LocalizationKeys.from.tr(context)} ${DateFormat('hh:mm a').format(singleEvent.startDate!)} ${LocalizationKeys.to.tr(context)} ${DateFormat('hh:mm a').format(singleEvent.endDate!)}"
                                              : DateFormat('dd MMM,yyyy - hh:mm a').format(singleEvent.endDate!),
                                          textAlign: TextAlign.start,
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w500,
                                            color: context.colors.greyLight,
                                          ),
                                        ),
                                    ],
                                  )
                                ],
                              ),
                              if (
                                  singleEvent.requiredPaid != null &&
                                  isSuccess(singleEvent.requiredPaid))
                                SizedBox(height: 25.csh),
                              if (
                                  singleEvent.requiredPaid != null &&
                                  isSuccess(singleEvent.requiredPaid))
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const IconCardWidget(
                                          icon: FontAwesomeIcons.tags,
                                        ),
                                        SizedBox(width: 15.csh),
                                        if (!(singleEvent.priceAfterDiscount == null &&
                                            singleEvent.priceBeforeDiscount == null))
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    (singleEvent.priceAfterDiscount != null)
                                                        ? singleEvent.priceAfterDiscount.toString()
                                                        : singleEvent.priceBeforeDiscount.toString(),
                                                    textAlign: TextAlign.start,
                                                    style: TextStyle(
                                                      fontSize: 28.sp,
                                                      fontWeight: FontWeight.w500,
                                                      color: context.colors.primary,
                                                    ),
                                                  ),
                                                  SizedBox(width: 5.csw),
                                                  Text(
                                                    singleEvent.currency,
                                                    textAlign: TextAlign.start,
                                                    style: TextStyle(
                                                      fontSize: 15.sp,
                                                      fontWeight: FontWeight.w500,
                                                      color: context.colors.primary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 2.csh),
                                              if (singleEvent.priceAfterDiscount != null &&
                                                  singleEvent.priceBeforeDiscount != null)
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      singleEvent.priceBeforeDiscount.toString(),
                                                      textAlign: TextAlign.start,
                                                      style: TextStyle(
                                                        fontSize: 14.sp,
                                                        fontWeight: FontWeight.w500,
                                                        color: context.colors.greyLight,
                                                        decoration: TextDecoration.lineThrough,
                                                      ),
                                                    ),
                                                    Text(
                                                      ' ${singleEvent.currency} ',
                                                      textAlign: TextAlign.start,
                                                      style: TextStyle(
                                                        fontSize: 14.sp,
                                                        fontWeight: FontWeight.w500,
                                                        color: context.colors.greyLight,
                                                        decoration: TextDecoration.lineThrough,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        const Spacer(),
                                        if (singleEvent.eventForUserModel != null)
                                          PaidOrNotPaidWidget(
                                            isPaid: singleEvent.eventForUserModel!.isPaid ?? false,
                                            date: singleEvent.eventForUserModel!.approvedDate,
                                          ),
                                      ],
                                    ),
                                    // if (singleEvent.price_for_all_children && context.isProfessors)
                                    //   Text(
                                    //     textAlign: TextAlign.start,
                                    //     LocalizationKeys.price_for_all_children.tr(context),
                                    //     style: TextStyle(
                                    //       fontSize: 16.sp,
                                    //       fontWeight: FontWeight.w300,
                                    //       color: context.colors.textColor,
                                    //     ),
                                    //   ),
                                    // if (!singleEvent.price_for_all_children && context.isProfessors)
                                    //   Text(
                                    //     LocalizationKeys.price_for_all_children.tr(context),
                                    //     textAlign: TextAlign.start,
                                    //     style: TextStyle(
                                    //       fontSize: 16.sp,
                                    //       fontWeight: FontWeight.w300,
                                    //       color: context.colors.textColor,
                                    //     ),
                                    //   ),
                                  ],
                                )
                            ],
                          ),
                        ),
                        if ((isSuccess(singleEvent.requiredPaid) &&
                                singleEvent.eventForUserModel?.isPaid == false) )
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 20.csh),
                            child: CustomButton(
                              title: LocalizationKeys.payment_made.tr(context),
                              onTap: () {
                                showButtonSheet(
                                    context: context,
                                    imageController: imageController,
                                    paymentInfo: singleEvent.paymentInfo,
                                    sendReceipt: () {
                                      if (image != null) {
                                        BlocProvider.of<SingleEventBloc>(context).add(
                                          PaymentEvent(
                                            eventId: singleEvent.id,
                                            image: image!,
                                          ),
                                        );
                                        Navigator.pop(context);
                                      }
                                    },
                                    uploadImage: () async {
                                      final f = await pickAttachments(context, multiple: false);
                                      if (validList(f)) {
                                        final file = f.first;
                                        imageController.value = File(file);
                                        image = XFile(file);
                                      }
                                    });
                              },
                            ),
                          ),

                        Builder(
                          builder: (context) {
                          return Column(children: [
                              if ((singleEvent.requiredApproval == true &&
                                      (eventForUserModel?.isApproved == null) &&
                                      singleEvent.deadLineForApproval != null &&
                                      singleEvent.deadLineForApproval!.isAfter(DateTime.now())) )
                                ApprovalSheetWidget(
                                  deadline: singleEvent.deadLineForApproval,
                                  onYes: () {
                                    BlocProvider.of<SingleEventBloc>(context).add(
                                      ApproveEvent(
                                        eventId: singleEvent.id,
                                      ),
                                    );
                                  },
                                  onNo: () {
                                    BlocProvider.of<SingleEventBloc>(context).add(
                                      NotApproveEvent(
                                        eventId: singleEvent.id,
                                      ),
                                    );
                                  },
                                ),
                              if (singleEvent.requiredApproval == true && (eventForUserModel?.isApproved != null))
                                ApprovedSheetWidget(
                                  name: validateString(eventForUserModel?.approvalUserName,UserBloc.get.state.user?.name??''),
                                  imageUrl: validateString(eventForUserModel?.approvalImageUrl,UserBloc.get.state.user?.image??''),
                                  date: eventForUserModel?.approvedDate,
                                  isApproved: eventForUserModel?.isApproved ?? false,
                                ),
                            ]);
                          }
                        ),
                      ],
                    ),
                  );
                default:
                  return Container();
              }
            },
          ),
        ),
      ),
    );
  }
}

bool getTextLines(String text, BuildContext context) {
  final span = TextSpan(text: text);
  final tp = TextPainter(text: span, maxLines: 3, textDirection: Directionality.of(context));
  tp.layout(maxWidth: MediaQuery.of(context).size.width); // equals the parent screen width
  //false for maxlines 3
  //true for maxlines 1
  return tp.didExceedMaxLines;
}
