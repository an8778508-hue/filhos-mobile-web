import 'package:country_picker/country_picker.dart';
import 'package:escola/core/components/buttons/button_with_icon.dart';
import 'package:escola/core/components/fields/error_field.dart';
import 'package:escola/core/components/fields/phone_field.dart';
import 'package:escola/core/components/icons/common_image.dart';
import 'package:escola/core/components/text/professors_container.dart';
import 'package:escola/core/config/widgets/config_builder.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/app_constants.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/login/presentation/bloc/login_bloc.dart';
import 'package:escola/features/otp/models/otp_error_model.dart';
import 'package:escola/features/otp/presentation/otp_screen.dart';
import 'package:escola/features/privacy_policy/privacy_policy_screen.dart';
import 'package:escola/features/terms_and_condtions/terms_and_conditions_screen.dart';
import 'package:escola/flavors/app_flavors.dart';
import 'package:escola/shared/assets/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.hasBackButton = false});

  final bool hasBackButton;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();

  late TextEditingController phoneController;
  late TextEditingController passwordController;
  late ValueNotifier<bool> rememberMeToggle;
  late Country country;

  String? verificationId;

  bool isValidNumber = false;
  bool showValidNumberError = false;

  @override
  void initState() {
    // phoneController = TextEditingController(text: isDriver ?'01000000004':'01000000001');
    phoneController = TextEditingController();
    passwordController = TextEditingController();
    rememberMeToggle = ValueNotifier(false);
    // todo
    country = Country.parse(AppConstants.egCountryCode);
    super.initState();
  }

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    rememberMeToggle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LoginBloc>(
      create: (BuildContext context) => di<LoginBloc>(),
      child: BlocListener<LoginBloc, LoginState>(
        listener: (BuildContext context, LoginState state) async {
          if (state is LoginReady) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: BlocProvider.of<LoginBloc>(context),
                  child: OTPScreen(
                    phone: phoneController.text,
                    phoneCode: country.phoneCode,
                    countryCode: country.countryCode,
                    rememberMe: rememberMeToggle.value,
                  ),
                ),
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: context.colors.scaffold,
          body: SafeArea(
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    if (widget.hasBackButton) SizedBox(height: 10.h),
                    if (widget.hasBackButton)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 15.csw, vertical: 10.csh),
                            child: Icon(
                              Icons.arrow_back_ios_rounded,
                              color: context.colors.primary,
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            SizedBox(
                              height: 66.csh,
                            ),
                            SizedBox(
                              height: 90.h,
                              width: 210.csw,
                              child: ConfigSelector(
                                selector: (config) => config.logo_horizontal,
                                builder: (context, logo) => CommonImage(
                                  imageUrl: logo ?? Assets.icons.defaultHorizontalLogo.path,
                                  fallBackImagePath: Assets.icons.defaultHorizontalLogo.path,
                                  height: 90.h,
                                  width: 210.csw,
                                ),
                              ),
                            ),
                            if (context.isProfessors) ...[
                              SizedBox(
                                height: 17.csh,
                              ),
                              ProfessorsContainer(
                                paddingHorizontal: 30.w,
                                paddingVertical: 5.h,
                                fontSize: 19.sp,
                              ),
                            ],
                            SizedBox(
                              height: context.isProfessors ? 40.h : 98.h,
                            ),
                            Text(
                              LocalizationKeys.login_title.tr(context),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20.sp,
                                color: context.colors.textColor,
                                height: 1,
                              ),
                            ),
                            SizedBox(
                              height: 40.csh,
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 42.csw),
                              child: PhoneField(
                                background: context.colors.background,
                                padding: EdgeInsets.symmetric(vertical: 5.csh, horizontal: 20.csw),
                                borderRadius: 30.r,
                                onChanged: (value) {
                                  // if (!showValidNumberError) {
                                  //   setState(() => showValidNumberError = true);
                                  // }
                                },
                                isCountryValid: (valid) {
                                  setState(() => isValidNumber = valid);
                                },
                                validator: (value) {
                                  if (!validString(value)) {
                                    return LocalizationKeys.this_field_cant_be_empty.tr(context);
                                  }
                                  return null;
                                },
                                initial: phoneController.text,
                                phoneController: phoneController,
                                strokeWidth: 0.0,
                                strokeColor: Colors.transparent,
                                marginErrorWidthPercentage: 0.0,
                                onCountrySelected: (Country value) {
                                  if (mounted) {
                                    setState(() {
                                      country = value;
                                    });
                                  }
                                },
                                country: country,
                              ),
                            ),
                            if (!isValidNumber && showValidNumberError) ...[
                              SizedBox(
                                height: 10.csh,
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 42.csw),
                                child: ErrorField(
                                  text: LocalizationKeys.please_enter_a_valid_phone_number.tr(context),
                                ),
                              ),
                            ],
                            SizedBox(
                              height: 20.csh,
                            ),
                            Row(
                              children: [
                                SizedBox(
                                  width: 42.csw,
                                ),
                                const Spacer(),
                                GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: () {
                                    rememberMeToggle.value = !rememberMeToggle.value;
                                  },
                                  child: Row(
                                    children: [
                                      ValueListenableBuilder(
                                        valueListenable: rememberMeToggle,
                                        builder: (context, v, child) => SizedBox(
                                          width: 20.w,
                                          height: 20.w,
                                          child: Theme(
                                            data: Theme.of(context).copyWith(
                                              unselectedWidgetColor: context.colors.primary,
                                            ),
                                            child: Checkbox(
                                              value: v,
                                              shape: RoundedRectangleBorder(
                                                  side: BorderSide(color: context.colors.accent)),
                                              onChanged: (value) {
                                                rememberMeToggle.value = !rememberMeToggle.value;
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 5.w),
                                      Text(
                                        LocalizationKeys.keep_me_logged_in.tr(context),
                                        style: TextStyle(
                                          color: context.colors.textColor,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),

                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 42.csw,
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 40.csh,
                            ),
                            BlocBuilder<LoginBloc, LoginState>(
                              builder: (context, state) =>
                                  state is LoginFailure && state.failure.message != const OTPErrorModel.timeout().code
                                      ? Padding(
                                          padding: const EdgeInsets.only(bottom: 20.0),
                                          child: Center(child: ErrorField(text: state.failure.message.tr(context))),
                                        )
                                      : const SizedBox(),
                            ),
                            BlocSelector<LoginBloc, LoginState, bool>(
                              selector: (state) => state is LoginLoading,
                              builder: (context, loading) => ButtonWithIcon(
                                isLoading: loading,
                                hasError: !isValidNumber,
                                mainAxisAlignment: MainAxisAlignment.center,
                                onPressed: () {
                                  formKey.currentState?.save();
                                  if (formKey.currentState?.validate() ?? false) {
                                    BlocProvider.of<LoginBloc>(context).requestOTP(
                                      phone: "+${country.phoneCode + phoneController.text}",
                                      countryCode: country.countryCode,
                                    );
                                  }
                                },
                                buttonBackgroundColor: context.colors.primary,
                                textColor: context.colors.secondaryTextColor,
                                text: LocalizationKeys.login.tr(context),
                                marginWidth: 40.w,
                                marginHeight: 0,
                                padding: EdgeInsets.symmetric(vertical: 10.h),
                                borderRadius: 30.r,
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(
                              height: 20.csh,
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 40.w),
                              child: Text.rich(
                                textAlign: TextAlign.center,
                                TextSpan(
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: context.colors.labelColor,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: LocalizationKeys.by_continuing_i_agree.tr(context),
                                    ),
                                    WidgetSpan(
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.push(context,
                                              MaterialPageRoute(builder: (context) => const TermsAndConditions()));
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.h),
                                          child: Text(
                                            LocalizationKeys.terms_and_conditions.tr(context),
                                            style: TextStyle(
                                              decoration: TextDecoration.underline,
                                              color: context.colors.labelColor,
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                      ),
                                      alignment: PlaceholderAlignment.middle,
                                    ),
                                    TextSpan(
                                      text: LocalizationKeys.and.tr(context),
                                    ),
                                    WidgetSpan(
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.push(
                                              context, MaterialPageRoute(builder: (context) => const PrivacyPolicy()));
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2),
                                          child: Text(
                                            LocalizationKeys.privacy_policy.tr(context),
                                            style: TextStyle(
                                              decoration: TextDecoration.underline,
                                              color: context.colors.labelColor,
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                      ),
                                      alignment: PlaceholderAlignment.middle,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 20.csh,
                            ),
                            // ButtonWithIcon(
                            //   mainAxisAlignment: MainAxisAlignment.center,
                            //   onPressed: () {
                            //     // Navigator.push(context, MaterialPageRoute(builder: (_) => const NewVisitorScreen()));
                            //   },
                            //   buttonBackgroundColor: context.colors.disabled,
                            //   textColor: context.colors.divider,
                            //   padding: EdgeInsets.symmetric(vertical: 10.h),
                            //   text: LocalizationKeys.new_visitor.tr(context),
                            //   borderRadius: 30.r,
                            //   fontSize: 16.sp,
                            //   fontWeight: FontWeight.bold,
                            // ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
