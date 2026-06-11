
import 'package:escola/core/components/buttons/button_with_icon.dart';
import 'package:escola/core/components/fields/custom_text_field.dart';
import 'package:escola/core/components/fields/error_field.dart';
import 'package:escola/core/components/icons/common_image.dart';
import 'package:escola/core/components/text/professors_container.dart';
import 'package:escola/core/config/widgets/config_builder.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/login/presentation/bloc/login_bloc.dart';
import 'package:escola/features/otp/models/otp_delivery_mode.dart';
import 'package:escola/features/otp/presentation/otp_screen.dart';
import 'package:escola/features/register/bloc/register_bloc.dart';
import 'package:escola/features/register/bloc/register_event.dart';
import 'package:escola/features/register/bloc/register_state.dart';
import 'package:escola/flavors/app_flavors.dart';
import 'package:escola/shared/assets/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/components/widgets/app_bar.dart';
import '../../privacy_policy/privacy_policy_screen.dart';
import '../../settings/edit_profile/widgets/edit_profile_field_tile.dart';
import '../../terms_and_condtions/terms_and_conditions_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;

  @override
  void initState() {
    nameController = TextEditingController();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  RegisterParamaters _buildParams() => RegisterParamaters(
        name: nameController.text,
        email: emailController.text.trim(),
        password: passwordController.text,
        confirmPassword: confirmPasswordController.text,
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RegisterBloc>(
      create: (BuildContext context) => di<RegisterBloc>(),
      child: BlocListener<RegisterBloc, RegisterStates>(
        listener: (context, state) {
          // Step 1 done: the verification code has been emailed. Move to the
          // OTP screen, which verifies the code and then creates the account.
          if (state is RegisterOtpSentState) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider<LoginBloc>(
                  create: (_) => di<LoginBloc>(),
                  child: OTPScreen(
                    mode: OTPDeliveryMode.email,
                    email: emailController.text.trim(),
                    maskedEmail: state.maskedEmail,
                    registerParams: _buildParams(),
                  ),
                ),
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: context.colors.scaffold,
          appBar: MyAppBar(
            title: LocalizationKeys.create_account.tr(context),
            hasNotification: false,
          ),
          body: SafeArea(
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 42.w),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 50.csh,
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
                              BlocBuilder<RegisterBloc, RegisterStates>(
                                builder: (context, state) {
                                  if (state is ErrorRegisterState) {
                                    return Padding(
                                      padding: EdgeInsets.only(top: 20.0),
                                      child: Center(child: ErrorField(text: state.error)),
                                    );
                                  }
                                  return const SizedBox();
                                },
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
                                height: context.isProfessors ? 40.h : 50.h,
                              ),
                              const FieldTitle(textKey: LocalizationKeys.name),
                              CustomTextField(
                                controller: nameController,
                                hint: LocalizationKeys.name.tr(context),
                                backgroundColor: context.colors.background,
                                padding: EdgeInsets.symmetric(vertical: 5.csh, horizontal: 20.csw),
                                borderRadius: 30.r,
                                validator: (value) {
                                  if (!validString(value)) {
                                    return LocalizationKeys.this_field_cant_be_empty.tr(context);
                                  }
                                  return null;
                                },
                                keyboardType: TextInputType.name,
                              ),
                              SizedBox(
                                height: 20.csh,
                              ),
                              const FieldTitle(textKey: LocalizationKeys.email),
                              CustomTextField(
                                controller: emailController,
                                hint: LocalizationKeys.email.tr(context),
                                backgroundColor: context.colors.background,
                                padding: EdgeInsets.symmetric(vertical: 5.csh, horizontal: 20.csw),
                                borderRadius: 30.r,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (!validString(value)) {
                                    return LocalizationKeys.this_field_cant_be_empty.tr(context);
                                  }
                                  final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                  if (!emailRegExp.hasMatch(value!)) {
                                    return LocalizationKeys.this_is_not_a_valid_email.tr(context);
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(
                                height: 20.csh,
                              ),
                              const FieldTitle(textKey: LocalizationKeys.password),
                              CustomTextField(
                                controller: passwordController,
                                hint: LocalizationKeys.password.tr(context),
                                backgroundColor: context.colors.background,
                                padding: EdgeInsets.symmetric(vertical: 5.csh, horizontal: 20.csw),
                                borderRadius: 30.r,
                                obscurePasswordController: ValueNotifier(true),
                                isPassword: true,
                                maxLines: 1, // Explicitly set to 1 for password fields
                                validator: (value) {
                                  if (!validString(value) || (value?.length ?? 0) < 6) {
                                    return "${LocalizationKeys.this_field_cant_be_empty_or_less_than.tr(context)} 6 ${LocalizationKeys.character.tr(context)}";
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(
                                height: 20.csh,
                              ),
                              const FieldTitle(textKey: LocalizationKeys.password_confirmation),
                              CustomTextField(
                                controller: confirmPasswordController,
                                hint: LocalizationKeys.password_confirmation.tr(context),
                                backgroundColor: context.colors.background,
                                padding: EdgeInsets.symmetric(vertical: 5.csh, horizontal: 20.csw),
                                borderRadius: 30.r,
                                obscurePasswordController: ValueNotifier(true),
                                isPassword: true,
                                maxLines: 1, // Explicitly set to 1 for password fields
                                validator: (value) {
                                  if (!validString(value)) {
                                    return LocalizationKeys.this_field_cant_be_empty.tr(context);
                                  }
                                  if (passwordController.text != value) {
                                    return LocalizationKeys.password_doesnot_match.tr(context);
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(
                                height: 40.csh,
                              ),
                              BlocSelector<RegisterBloc, RegisterStates, bool>(
                                selector: (state) => state is LoadingRegisterState,
                                builder: (context, loading) => ButtonWithIcon(
                                  isLoading: loading,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  onPressed: () {
                                    final currentState = formKey.currentState;
                                    if (currentState != null) {
                                      // This ensures the form has the latest values from controllers
                                      currentState.save();
                                      if (currentState.validate()) {
                                        // Step 1: email the verification code; account is
                                        // created on the OTP screen after it is confirmed.
                                        context.read<RegisterBloc>().sendEmailOtp(
                                              email: emailController.text.trim(),
                                            );
                                      }
                                    }
                                  },
                                  buttonBackgroundColor: context.colors.primary,
                                  textColor: context.colors.secondaryTextColor,
                                  text: LocalizationKeys.confirm.tr(context),
                                  marginWidth: 0.w,
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
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => const TermsAndConditions()),
                                            );
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
                                              context,
                                              MaterialPageRoute(builder: (context) => const PrivacyPolicy()),
                                            );
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
                            ],
                          ),
                        ),
                      ),
                    )
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
