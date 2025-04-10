import 'package:brasil_fields/brasil_fields.dart';
import 'package:country_picker/country_picker.dart';
import 'package:escola/core/utils/safe_x.dart';
import 'package:escola/flavors/app_flavors.dart';
import 'package:escola/core/attachment_selection/attachment_src.dart';
import 'package:escola/core/attachment_selection/show_attachment_selection_bottomsheet.dart';
import 'package:escola/core/components/buttons/button_with_icon.dart';
import 'package:escola/core/components/fields/custom_text_field.dart';
import 'package:escola/core/components/fields/error_field.dart';
import 'package:escola/core/components/fields/phone_field.dart';
import 'package:escola/core/components/fields/selectable_field.dart';
import 'package:escola/core/components/fromatters/row_formatters.dart';
import 'package:escola/core/components/icons/common_image.dart';
import 'package:escola/core/components/items/address/title_item.dart';
import 'package:escola/core/components/loading/loading.dart';
import 'package:escola/core/components/sheets/selectable_sheet.dart';
import 'package:escola/core/components/widgets/app_bar.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/models/multi_select_model.dart';
import 'package:escola/core/user/bloc/user_bloc.dart';
import 'package:escola/core/utils/app_constants.dart';
import 'package:escola/core/utils/constants/constant_values.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/funuctions/global_functions.dart';
import 'package:escola/core/utils/size_config.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/settings/edit_profile/bloc/edit_profile_events.dart';
import 'package:escola/features/settings/edit_profile/bloc/edit_profile_states.dart';
import 'package:escola/features/settings/edit_profile/choose_image.dart';
import 'package:escola/features/settings/edit_profile/models/class_model.dart';
import 'package:escola/features/settings/edit_profile/models/title_model.dart';
import 'package:escola/features/settings/edit_profile/widgets/edit_profile_field_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import 'bloc/edit_profile_bloc.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController externalEmailController;
  late final TextEditingController phoneController;
  late final TextEditingController secondaryPhoneController;
  late final TextEditingController cpfController;

  late final ValueNotifier<bool> rememberMeToggle;
  late final ValueNotifier<bool> obscurePasswordController;
  late final ValueNotifier<Uint8List?> imageFile;
  late final ValueNotifier<int> gender;
  // late final ValueNotifier<List<ClassModel>> selectedClassModels;
  late final ValueNotifier<TitleModel?> selectedTitle;
  late final ValueNotifier<Country> secondaryCountry;
  late final ValueNotifier<Country> country;
  late final ValueNotifier<List<String>> externalEmails;
  late final ValueNotifier<List<String>> externalPhones;

  XFile? pickedImage;

  bool get isBrazil => isBrazilCountry(country.value.countryCode);

  bool get isProfessors => context.isProfessors;

  @override
  void initState() {
    initValueNotifiers();
    initControllers();
    super.initState();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    externalEmailController.dispose();
    cpfController.dispose();
    phoneController.dispose();
    secondaryPhoneController.dispose();
    country.dispose();
    secondaryCountry.dispose();
    // selectedClassModels.dispose();
    selectedTitle.dispose();
    imageFile.dispose();
    gender.dispose();
    rememberMeToggle.dispose();
    obscurePasswordController.dispose();
    externalEmails.dispose();
    externalPhones.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    return BlocProvider<EditProfileBloc>(
      create: (context) => di<EditProfileBloc>()..add(FetchEditProfileEvent()),
      child: Builder(
        builder: (context) {
          return BlocConsumer<EditProfileBloc, EditProfileStates>(
            listener: (context, state) {
              if (state is SuccessEditProfileState) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  backgroundColor: context.colors.success,
                  content: Text(LocalizationKeys.profile_updated_successfully.tr(context)),
                ));
                Navigator.of(context).pop();
              }
            },
            builder: (c, state) {
              return Scaffold(
                backgroundColor: context.colors.scaffold,
                appBar: MyAppBar(
                  title: LocalizationKeys.my_information.tr(context),
                  hasNotification: true,
                ),
                body: GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                  },
                  child: BlocSelector<EditProfileBloc, EditProfileStates, bool>(
                    selector: (state) => state is LoadingEditProfileState,
                    builder: (context, loading) => loading
                        ? const Center(child: Loading())
                        : Column(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: EdgeInsets.only(bottom: 20.h),
                                  child: Column(
                                    children: <Widget>[
                                      SizedBox(height: getHeightByNumber(30)),
                                      SizedBox(
                                        width: getWidthByNumber(150),
                                        height: getWidthByNumber(150),
                                        child: Stack(
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.all(getWidthByNumber(10)),
                                              child: Container(
                                                clipBehavior: Clip.antiAlias,
                                                padding: EdgeInsets.all(getWidthByNumber(0)),
                                                decoration: BoxDecoration(
                                                    color: context.colors.background,
                                                    borderRadius: BorderRadius.circular(100.r)),
                                                width: getWidthByNumber(130),
                                                height: getWidthByNumber(130),
                                                child: ValueListenableBuilder(
                                                  valueListenable: imageFile,
                                                  builder: (BuildContext context, value, Widget? child) =>
                                                      imageFile.value == null
                                                          ? validString(UserBloc.get.state.user?.image)
                                                              ? CommonImage(
                                                                  imageUrl: UserBloc.get.state.user?.image,
                                                                  fit: BoxFit.cover,
                                                                )
                                                              : Padding(
                                                                  padding: EdgeInsets.all(getWidthByNumber(30)),
                                                                  child: Image.asset(
                                                                    'assets/images/default_profile.png',
                                                                    height: getWidthByNumber(130),
                                                                    width: getWidthByNumber(130),
                                                                    fit: BoxFit.fitHeight,
                                                                  ),
                                                                )
                                                          : Image.memory(
                                                              imageFile.value!,
                                                              height: getWidthByNumber(130),
                                                              width: getWidthByNumber(130),
                                                              fit: BoxFit.cover,
                                                            ),
                                                ),
                                              ),
                                            ),
                                            Positioned.directional(
                                              textDirection: TextDirection.ltr,
                                              bottom: 0.0,
                                              end: 0.0,
                                              child: IconButton(
                                                iconSize: getWidthByNumber(46),
                                                onPressed: () async {
                                                  final result = await showAttachmentSelectionBottomSheet(context);
                                                  if (!context.mounted) {
                                                    return;
                                                  }
                                                  if (result == null) {
                                                    return;
                                                  }
                                                  late final ImageSource src;
                                                  switch (result) {
                                                    case AttachmentSrc.gallery:
                                                      src = ImageSource.gallery;
                                                      break;
                                                    case AttachmentSrc.camera:
                                                      src = ImageSource.camera;
                                                      break;
                                                    default:
                                                      return;
                                                  }
                                                  chooseImage(
                                                    imageSource: src,
                                                    context: c,
                                                    onFinish: (p0, image) {
                                                      imageFile.value = p0;
                                                      pickedImage = image;
                                                    },
                                                  );
                                                },
                                                icon: Container(
                                                    width: getWidthByNumber(46),
                                                    height: getWidthByNumber(46),
                                                    clipBehavior: Clip.antiAlias,
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(100.r),
                                                      border: Border.all(
                                                        color: context.colors.background,
                                                      ),
                                                    ),
                                                    child: SvgPicture.asset(
                                                      'assets/icons/pic.svg',
                                                    )),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 30.w),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(height: getHeightByNumber(25)),
                                            BlocBuilder<EditProfileBloc, EditProfileStates>(
                                              builder: (context, state) => state is ErrorEditProfileState
                                                  ? ErrorField(text: state.error)
                                                  : const SizedBox(),
                                            ),
                                            SizedBox(height: getHeightByNumber(15)),
                                            Form(
                                              key: formKey,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  PhoneField(
                                                    background: context.colors.background,
                                                    padding: EdgeInsets.symmetric(vertical: 5.csh, horizontal: 20.csw),
                                                    borderRadius: 30.r,
                                                    validator: (value) {
                                                      if (!validString(value)) {
                                                        return LocalizationKeys.this_field_cant_be_empty.tr(context);
                                                      }
                                                      // if (!validateMobile(value!)) {
                                                      //   return LocalizationKeys.this_is_not_a_valid_mobile.tr(context);
                                                      // }
                                                      return null;
                                                    },
                                                    initial: phoneController.text,
                                                    phoneController: phoneController,
                                                    strokeWidth: 0.0,
                                                    strokeColor: Colors.transparent,
                                                    marginErrorWidthPercentage: 0.0,
                                                    readOnly: true,
                                                    onCountrySelected: (Country value) {
                                                      // country.value = value;
                                                    },
                                                    country: country.value,
                                                  ),
                                                  SizedBox(
                                                    height: getHeightByNumber(18),
                                                  ),
                                                  const FieldTitle(textKey: LocalizationKeys.name),
                                                  CustomTextField(
                                                    initial: nameController.text,
                                                    validator: (value) {
                                                      if (!validString(value)) {
                                                        return LocalizationKeys.this_field_cant_be_empty.tr(context);
                                                      }
                                                      return null;
                                                    },
                                                    controller: nameController,
                                                    backgroundColor: context.colors.background,
                                                    hasBorder: false,
                                                    padding: EdgeInsets.symmetric(
                                                        vertical: getHeightByNumber(5), horizontal: 20.w),
                                                    borderColor: context.colors.primary,
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    hintColor: context.colors.divider,
                                                    hint: LocalizationKeys.user_name.tr(context),
                                                    maxLines: 1,
                                                    borderRadius: 30.sp,
                                                    fontSize: 16.sp,
                                                    fontWeight: FontWeight.w300,
                                                    textInputAction: TextInputAction.done,
                                                  ),
                                                  SizedBox(
                                                    height: getHeightByNumber(18),
                                                  ),
                                                  const FieldTitle(textKey: LocalizationKeys.email),
                                                  CustomTextField(
                                                    initial: emailController.text,
                                                    validator: (value) {
                                                      if (!validString(value)) {
                                                        return LocalizationKeys.this_field_cant_be_empty.tr(context);
                                                      }
                                                      return null;
                                                    },
                                                    controller: emailController,
                                                    backgroundColor: context.colors.background,
                                                    hasBorder: false,
                                                    padding: EdgeInsets.symmetric(
                                                        vertical: getHeightByNumber(5), horizontal: 20.w),
                                                    borderColor: context.colors.primary,
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    hintColor: context.colors.divider,
                                                    hint: LocalizationKeys.user_name.tr(context),
                                                    maxLines: 1,
                                                    borderRadius: 30.sp,
                                                    fontSize: 16.sp,
                                                    fontWeight: FontWeight.w300,
                                                    textInputAction: TextInputAction.done,
                                                  ),
                                                  if (isProfessors) ...[
                                                    SizedBox(
                                                      height: getHeightByNumber(20),
                                                    ),
                                                    ValueListenableBuilder(
                                                      valueListenable: gender,
                                                      builder: (context, value, child) => Row(
                                                        children: [
                                                          Expanded(
                                                            child: buildGenderButton(
                                                              maleGenderId,
                                                              LocalizationKeys.male,
                                                            ),
                                                          ),
                                                          SizedBox(width: 16.w),
                                                          Expanded(
                                                            child: buildGenderButton(
                                                              femaleGenderId,
                                                              LocalizationKeys.female,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                  SizedBox(
                                                    height: getHeightByNumber(20),
                                                  ),
                                                  ValueListenableBuilder(
                                                    valueListenable: country,
                                                    builder: (context, value, child) => Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        if (isBrazil) const FieldTitle(textKey: LocalizationKeys.cpf),
                                                        if (isBrazil)
                                                          RowFormatters(
                                                            controller: cpfController,
                                                            label: '',
                                                            formatter: CpfInputFormatter(),
                                                          ),
                                                        if (isBrazil) SizedBox(height: getHeightByNumber(18)),
                                                      ],
                                                    ),
                                                  ),
                                                  //todo
                                                  if (isProfessors ) ...[
                                                    const FieldTitle(textKey: LocalizationKeys.title),
                                                    ValueListenableBuilder(
                                                      valueListenable: selectedTitle,
                                                      builder: (context, selected, child) {
                                                        final selectedModel = BlocProvider.of<EditProfileBloc>(context).titles.value.safeFirstWhere((element) => element.id == selected?.id)??selected;
                                                        return ValueListenableBuilder(
                                                          valueListenable:
                                                              BlocProvider.of<EditProfileBloc>(context).titles,
                                                          builder: (context, titles, child) =>
                                                              SelectableField<TitleModel>(
                                                            whereCondition: (model, String searchValue) {
                                                              return model.name
                                                                  .toLowerCase()
                                                                  .contains(searchValue.toLowerCase().trim());
                                                            },
                                                            item: (model) => TitleItem(
                                                              model: model,
                                                              selected: selectedModel,
                                                            ),
                                                            list: titles,
                                                            onSelected: (value) {
                                                              selectedTitle.value = value;
                                                            },
                                                            value: selectedModel?.name,
                                                            hintKey: (LocalizationKeys.title).tr(context),
                                                            background: Colors.white,
                                                            padding: EdgeInsetsDirectional.symmetric(
                                                              vertical: getHeightByNumber(20),
                                                            ).add(EdgeInsetsDirectional.only(
                                                              start: getWidthByNumber(20),
                                                              end: getWidthByNumber(10),
                                                            )),
                                                            borderRadius: 30.r,
                                                            validator: (_) {
                                                              if (selectedTitle == null) {
                                                                return (LocalizationKeys.this_field_cant_be_empty)
                                                                    .tr(context);
                                                              }
                                                              return null;
                                                            },
                                                            strokeWidth: 0.0,
                                                            strokeColor: context.colors.background,
                                                            elevation: 0,
                                                            marginErrorWidthPercentage: 0.0,
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                  if (isProfessors&& false) ...[
                                                    SizedBox(height: getHeightByNumber(30)),
                                                    ValueListenableBuilder(
                                                      valueListenable: externalPhones,
                                                      builder: (context, externalPhonesVal, child) => FieldTitle(
                                                        textKey: LocalizationKeys.external_phone,
                                                        externalButtonKey: LocalizationKeys.add_phone,
                                                        onTap: () {
                                                          print(
                                                              '_EditProfileScreenState.build ${secondaryPhoneController.text}');
                                                          print(
                                                              '_EditProfileScreenState.build ${secondaryPhoneController.text.isNotEmpty}');
                                                          if (secondaryPhoneController.text.isNotEmpty) {
                                                            externalPhones.value.add(
                                                                '+${secondaryCountry.value.phoneCode + secondaryPhoneController.text}');
                                                            externalPhones.value = [...externalPhones.value];
                                                            secondaryPhoneController.text = '';
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                    PhoneField(
                                                      background: context.colors.background,
                                                      padding:
                                                          EdgeInsets.symmetric(vertical: 5.csh, horizontal: 20.csw),
                                                      borderRadius: 30.r,
                                                      validator: (value) {
                                                        // if (!validateMobile(value!)) {
                                                        //   return LocalizationKeys.this_is_not_a_valid_mobile.tr(context);
                                                        // }
                                                        return null;
                                                      },
                                                      initial: secondaryPhoneController.text,
                                                      phoneController: secondaryPhoneController,
                                                      strokeWidth: 0.0,
                                                      strokeColor: Colors.transparent,
                                                      marginErrorWidthPercentage: 0.0,
                                                      onCountrySelected: (Country value) {
                                                        secondaryCountry.value = value;
                                                      },
                                                      country: secondaryCountry.value,
                                                    ),
                                                    SizedBox(height: getHeightByNumber(14)),
                                                    ValueListenableBuilder(
                                                      valueListenable: externalPhones,
                                                      builder: (context, externalPhonesVal, child) =>
                                                          WrappedList(list: externalPhones),
                                                    ),
                                                    SizedBox(height: getHeightByNumber(14)),
                                                    ValueListenableBuilder(
                                                      valueListenable: externalEmails,
                                                      builder: (context, externalEmailsVal, child) => FieldTitle(
                                                        textKey: LocalizationKeys.external_email,
                                                        externalButtonKey: LocalizationKeys.add_email,
                                                        onTap: () {
                                                          if (externalEmailController.text.isNotEmpty) {
                                                            externalEmails.value.add(externalEmailController.text);
                                                            externalEmails.value = [...externalEmails.value];
                                                            externalEmailController.text = '';
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                    CustomTextField(
                                                      initial: externalEmailController.text,
                                                      validator: (value) {
                                                        return null;
                                                      },
                                                      controller: externalEmailController,
                                                      backgroundColor: context.colors.background,
                                                      hasBorder: false,
                                                      padding: EdgeInsets.symmetric(
                                                        vertical: getHeightByNumber(5),
                                                        horizontal: 20.w,
                                                      ),
                                                      borderColor: context.colors.primary,
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      hintColor: context.colors.divider,
                                                      hint: LocalizationKeys.external_email.tr(context),
                                                      maxLines: 1,
                                                      keyboardType: TextInputType.emailAddress,
                                                      borderRadius: 30.sp,
                                                      fontSize: 16.sp,
                                                      fontWeight: FontWeight.w300,
                                                      textInputAction: TextInputAction.done,
                                                    ),
                                                    SizedBox(height: getHeightByNumber(14)),
                                                    ValueListenableBuilder(
                                                      valueListenable: externalEmails,
                                                      builder: (context, externalEmailsVal, child) =>
                                                          WrappedList(list: externalEmails),
                                                    ),
                                                    // SizedBox(height: getHeightByNumber(20)),
                                                    // const FieldTitle(textKey: LocalizationKeys.professor_class),
                                                    // ValueListenableBuilder(
                                                    //   valueListenable:
                                                    //       BlocProvider.of<EditProfileBloc>(context).classes,
                                                    //   builder: (context, classes, child) => MultiSelectWidget(
                                                    //     hint: LocalizationKeys.professor_class.tr(context),
                                                    //     title: LocalizationKeys.professor_class.tr(context),
                                                    //     models: classes
                                                    //         .map((e) => MultiSelectModel(id: e.id, title: e.name))
                                                    //         .toList(),
                                                    //     initial: selectedClassModels.value
                                                    //         .map((e) => MultiSelectModel(id: e.id, title: e.name))
                                                    //         .toList(),
                                                    //     onSelect: (items) {
                                                    //       selectedClassModels.value = BlocProvider.of<EditProfileBloc>(
                                                    //               context)
                                                    //           .classes
                                                    //           .value
                                                    //           .where((element) => items.any((e) => element.id == e.id))
                                                    //           .toList();
                                                    //       selectedClassModels.value = [...selectedClassModels.value];
                                                    //     },
                                                    //   ),
                                                    // ),
                                                    // SizedBox(height: getHeightByNumber(14)),
                                                    // ValueListenableBuilder(
                                                    //   valueListenable: selectedClassModels,
                                                    //   builder: (context, val, child) {
                                                    //     return WrappedClassesList(list: selectedClassModels);
                                                    //   },
                                                    // ),
                                                  ],
                                                  SizedBox(height: getHeightByNumber(30)),
                                                  BlocSelector<EditProfileBloc, EditProfileStates, bool>(
                                                    selector: (state) => state is LoadingEditProfileState,
                                                    builder: (context, loading) => ButtonWithIcon(
                                                      marginWidth: 0.0,
                                                      marginHeight: 0.0,
                                                      isLoading: loading,
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      onPressed: () {
                                                        formKey.currentState!.save();
                                                        if (formKey.currentState!.validate()) {
                                                          BlocProvider.of<EditProfileBloc>(context).add(
                                                            SubmitEditProfileEvent(
                                                              phone: UserBloc.get.state.user!.phone,
                                                              name: nameController.text,
                                                              email: emailController.text,
                                                              cpf: cpfController.text,
                                                              avatar: pickedImage,
                                                              phones: externalPhones.value,
                                                              emails: externalEmails.value,
                                                              gender: gender.value,
                                                              // classes: selectedClassModels.value.map((e) => e.id).toList(),
                                                              title: selectedTitle.value?.id,
                                                            ),
                                                          );
                                                        }
                                                      },
                                                      buttonBackgroundColor: context.colors.primary,
                                                      textColor: context.colors.secondaryTextColor,
                                                      text: LocalizationKeys.save.tr(context),
                                                      borderRadius: 30.r,
                                                      fontSize: 20.sp,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(height: 20.h),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  buildGenderButton(int value, String key) {
    final bool selected = value == gender.value;
    return ButtonWithIcon(
      isLoading: false,
      mainAxisAlignment: MainAxisAlignment.center,
      onPressed: () {
        gender.value = value;
      },
      firstIconWidget: Container(
        height: 20.h,
        width: 20.h,
        decoration: BoxDecoration(
          color: context.colors.background,
          border: selected ? null : Border.all(color: (context.colors.greyDark), width: 1.csw),
          borderRadius: BorderRadius.circular(100.r),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (selected)
              Container(
                height: 10.h,
                width: 10.h,
                decoration: BoxDecoration(
                  color: context.colors.primary,
                  borderRadius: BorderRadius.circular(100.r),
                ),
              ),
          ],
        ),
      ),
      marginWidth: 0,
      marginHeight: 0,
      textAlign: TextAlign.center,
      isTextExpanded: true,
      buttonBackgroundColor: selected ? context.colors.selectedButtonColor : context.colors.background,
      textColor: selected ? context.colors.primary : context.colors.textColor,
      text: key.tr(context),
      padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 20.w),
      borderRadius: 30.r,
      fontSize: 16.sp,
      fontWeight: FontWeight.w400,
    );
  }

  void initControllers() {
    print('_EditProfileScreenState.initControllers ${UserBloc.get.state.user?.cpf}');
    nameController = TextEditingController(text: UserBloc.get.state.user?.name);
    emailController = TextEditingController(text: UserBloc.get.state.user?.email ?? '');
    externalEmailController = TextEditingController();
    cpfController = TextEditingController(text: UserBloc.get.state.user?.cpf ?? '');
    phoneController = TextEditingController(
        text: (UserBloc.get.state.user?.phone ?? '').replaceFirst('+', '').replaceFirst(country.value.phoneCode, ''));
    secondaryPhoneController = TextEditingController(text: '');
  }

  void initValueNotifiers() {
    country = ValueNotifier(Country.parse(validateString(UserBloc.get.state.user?.countryCode,AppConstants.brazilCountryCode)));
    secondaryCountry = ValueNotifier(country.value);
    // selectedClassModels = ValueNotifier(UserBloc.get.state.user?.classes ?? []);
    selectedTitle = ValueNotifier(UserBloc.get.state.user?.title);
    imageFile = ValueNotifier(null);
    gender = ValueNotifier((int.tryParse(UserBloc.get.state.user?.genderId ?? '') ?? maleGenderId));
    rememberMeToggle = ValueNotifier(false);
    obscurePasswordController = ValueNotifier(true);
    externalEmails = ValueNotifier((UserBloc.get.state.user?.emails ?? []).map((e) => e.email).toList());
    externalPhones = ValueNotifier((UserBloc.get.state.user?.phones ?? []).map((e) => e.number).toList());
  }
}

class WrappedList extends StatelessWidget {
  const WrappedList({
    super.key,
    required this.list,
  });

  final ValueNotifier<List<String>> list;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        for (int index = 0; index < list.value.length; index++)
          Container(
            padding: EdgeInsets.symmetric(vertical: 10.h).add(
              EdgeInsetsDirectional.only(
                start: 16.w,
              ),
            ),
            margin: EdgeInsetsDirectional.only(end: 16.w, top: 5.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2.r),
              color: context.colors.primary,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  list.value[index],
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 14.sp,
                    color: context.colors.secondaryTextColor,
                  ),
                ),
                SizedBox(
                  width: 10.w,
                ),
                GestureDetector(
                  onTap: () {
                    list.value.removeAt(index);
                    list.value = [...list.value];
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Icon(
                      Icons.close,
                      color: context.colors.secondaryTextColor,
                      size: 18.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class WrappedClassesList extends StatelessWidget {
  const WrappedClassesList({
    super.key,
    required this.list,
  });

  final ValueNotifier<List<ClassModel>> list;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        for (int index = 0; index < list.value.length; index++)
          Container(
            padding: EdgeInsets.symmetric(vertical: 10.h).add(
              EdgeInsetsDirectional.only(
                start: 16.w,
              ),
            ),
            margin: EdgeInsetsDirectional.only(end: 16.w, top: 5.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2.r),
              color: context.colors.primary,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  list.value[index].name,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 14.sp,
                    color: context.colors.secondaryTextColor,
                  ),
                ),
                SizedBox(
                  width: 10.w,
                ),
                GestureDetector(
                  onTap: () {
                    list.value.removeAt(index);
                    list.value = [...list.value];
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Icon(
                      Icons.close,
                      color: context.colors.secondaryTextColor,
                      size: 18.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
