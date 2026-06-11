import 'package:country_picker/country_picker.dart';
import 'package:escola/core/components/fields/custom_form_field.dart';
import 'package:escola/core/components/fields/error_field.dart';
import 'package:escola/core/components/loading/loading_linear.dart';
import 'package:escola/core/components/my_icon.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/user/bloc/user_bloc.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/login/presentation/bloc/login_bloc.dart';
import 'package:escola/features/main/presentation/main_screen.dart';
import 'package:escola/features/otp/models/otp_delivery_mode.dart';
import 'package:escola/features/otp/presentation/bloc/otp_bloc.dart';
import 'package:escola/features/otp/presentation/widgets/delivery_mode_chrome.dart';
import 'package:escola/features/register/bloc/register_event.dart';
import 'package:escola/features/your_account_under_review/presentation/your_account_under_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OTPScreen extends StatefulWidget {
  const OTPScreen({
    super.key,
    this.phone,
    this.phoneCode,
    this.countryCode,
    this.rememberMe = false,
    this.mode = OTPDeliveryMode.sms,
    this.email,
    this.maskedEmail,
    this.registerParams,
  });

  final String? phone, phoneCode, countryCode;
  final bool rememberMe;
  final OTPDeliveryMode mode;
  final String? email;
  final String? maskedEmail;

  /// When set, this OTP screen is part of the self sign-up flow: confirming the
  /// code verifies the email and then creates the account.
  final RegisterParamaters? registerParams;

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final formKey = GlobalKey<FormState>();
  final int codeLength = 6;

  late final ValueNotifier<bool> validPhone;

  late TextEditingController codeController;
  late Country country;

  @override
  void initState() {
    codeController = TextEditingController();
    validPhone = ValueNotifier(false);
    codeController.addListener(() {
      if (mounted) {
        validPhone.value = codeController.text.trim().isNotEmpty && codeController.text.trim().length == codeLength;
      }
    });
    super.initState();
  }

  void _submitCode(BuildContext context) {
    if (widget.mode == OTPDeliveryMode.email) {
      if (widget.registerParams != null) {
        BlocProvider.of<OTPBloc>(context).confirmEmailOtpForRegister(
          email: widget.email!,
          code: codeController.text,
          params: widget.registerParams!,
        );
      } else {
        BlocProvider.of<OTPBloc>(context).confirmEmailOTP(
          email: widget.email!,
          code: codeController.text,
        );
      }
    } else {
      BlocProvider.of<OTPBloc>(context).confirmSMSCode(
        phone: "+${widget.phoneCode! + widget.phone!}",
        code: codeController.text,
        countryCode: widget.countryCode!,
      );
    }
  }

  @override
  void dispose() {
    validPhone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OTPBloc>(
      create: (BuildContext context) {
        final bloc = di<OTPBloc>();
        if (widget.mode == OTPDeliveryMode.email) {
          bloc.currentMode = OTPDeliveryMode.email;
          bloc.currentMaskedEmail = widget.maskedEmail;
        }
        return bloc;
      },
      child: Builder(
        builder: (context) => BlocListener<OTPBloc, OTPState>(
          listener: (BuildContext context, OTPState state) async {
            if(state is OTPSuccess){
              if (UserBloc.get.state.user?.isApproval == true) {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) =>const MainScreen()),(route) => false,);
              }else{
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) =>const YourAccountUnderReviewScreen()),(route) => false,);
              }
            }
          },
          child: Directionality(
            textDirection: TextDirection.ltr,
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
                        SizedBox(height: 10.h),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: GestureDetector(
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
                            padding: EdgeInsets.symmetric(horizontal: 40.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 40.h),
                                DeliveryModeChrome(
                                  mode: widget.mode,
                                  phone: widget.phone,
                                  phoneCode: widget.phoneCode,
                                  maskedEmail: BlocProvider.of<OTPBloc>(context).currentMaskedEmail,
                                ),
                                SizedBox(height: 120.h),
                                BlocSelector<LoginBloc, LoginState, String?>(
                                  selector: (state) => state is LoginFailure ? state.failure.message.tr(context) : null,
                                  builder: (context, loginFail) => BlocSelector<OTPBloc, OTPState, String?>(
                                    selector: (state) => state is OTPFailure ? state.failure.message.tr(context) : null,
                                    builder: (context, otpFail) =>
                                    otpFail != null
                                        ? ErrorField(text: otpFail.tr(context))
                                        : loginFail != null
                                            ? ErrorField(text: loginFail.tr(context))
                                            : const SizedBox(),
                                  ),
                                ),
                                SizedBox(height: 20.h),
                                CustomFormField(
                                  initial: codeController.text,
                                  validator: (value) {
                                    if (!validString(value)) {
                                      return LocalizationKeys.this_field_cant_be_empty.tr(context);
                                    }
                                    if (!checkMinimum(value, codeLength)) {
                                      return "${LocalizationKeys.this_field_cant_be_empty_or_less_than.tr(context)} $codeLength ${LocalizationKeys.character.tr(context)}";
                                    }
                                    return null;
                                  },
                                  builder: (field) => BlocSelector<OTPBloc, OTPState, bool>(
                                    selector: (state) => state is OTPLoading,
                                    builder: (context, loading) => PinCodeTextField(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      controller: codeController,
                                      showCursor: false,
                                      focusNode: FocusNode(),
                                      keyboardType: TextInputType.number,
                                      autoFocus: true,
                                      boxShadows: [
                                        BoxShadow(
                                          color: context.colors.divider.withOpacity(0.09),
                                          offset: const Offset(0, 8),
                                          blurRadius: 28,
                                          spreadRadius: -2,
                                        )
                                      ],
                                      length: codeLength,
                                      obscureText: false,
                                      textStyle: TextStyle(
                                        color: context.colors.secondaryTextColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 26.sp,
                                      ),
                                      animationType: AnimationType.fade,
                                      animationDuration: const Duration(milliseconds: 300),
                                      pinTheme: PinTheme.defaults(
                                        borderRadius: BorderRadius.circular(15.r),
                                        borderWidth: 1.5.csw,
                                        inActiveBoxShadows: [
                                          BoxShadow(
                                            color: context.colors.primary,
                                          )
                                        ],
                                        shape: PinCodeFieldShape.underline,
                                        selectedColor: context.colors.primary,
                                        activeColor: context.colors.primary,
                                        activeFillColor: context.colors.primary,
                                        selectedFillColor: context.colors.primary,
                                        inactiveFillColor: context.colors.primary.withOpacity(0.5),
                                        inactiveColor: context.colors.primary.withOpacity(0.2),
                                        fieldHeight: 50.csw,
                                        fieldWidth: 50.csw,
                                      ),
                                      // Pass it here
                                      onChanged: (value) {
                                        setState(() {
                                          field.didChange(value);
                                        });
                                        if(value.length == 6 && !loading){
                                          _submitCode(context);
                                        }
                                      },
                                      appContext: context,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 22.csh,
                                ),
                                Align(
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        LocalizationKeys.did_not_receive_code.tr(context),
                                        style: TextStyle(
                                          // decoration: TextDecoration.underline,
                                          fontSize: 14.sp,
                                          color: context.colors.textColor,
                                          // height: 1.sp,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      // SizedBox(width: 10.w),
                                      const Spacer(),
                                      InkResponse(
                                        onTap: () {
                                          BlocProvider.of<LoginBloc>(context).clearError();
                                          if (widget.mode == OTPDeliveryMode.email) {
                                            BlocProvider.of<OTPBloc>(context).resendEmailOTP(
                                              email: widget.email!,
                                            );
                                          } else {
                                            BlocProvider.of<OTPBloc>(context).resendOTP(
                                              phone: "+${widget.phoneCode! + widget.phone!}",
                                              countryCode: widget.countryCode!,
                                            );
                                          }
                                        },
                                        child: Text(
                                          LocalizationKeys.resend_again.tr(context),
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            decoration: TextDecoration.underline,
                                            color: context.colors.textColor,
                                            height: 1.2.sp,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: 45.csh,
                                ),
                                BlocSelector<OTPBloc, OTPState, bool>(
                                  selector: (state) => state is OTPLoading,
                                  builder: (context, loading) => loading ? const LoadingLinear() : const SizedBox(),
                                ),
                                BlocSelector<OTPBloc, OTPState, bool>(
                                  selector: (state) => state is OTPLoading,
                                  builder: (context, loading) =>  ValueListenableBuilder(
                                    valueListenable: BlocProvider.of<OTPBloc>(context).ready,
                                    builder: (context, ready, child) =>  ready && !(loading)
                                        ? Row(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              const Spacer(),
                                              BlocSelector<OTPBloc, OTPState, bool>(
                                                selector: (state) => state is OTPLoading,
                                                builder: (context, loading) => ValueListenableBuilder(
                                                  valueListenable: validPhone,
                                                  builder: (context, value, child) => GestureDetector(
                                                    onTap: () {
                                                      formKey.currentState?.save();
                                                      final valid = formKey.currentState?.validate();
                                                      validPhone.value = valid ?? false;
                                                      if (valid ?? false) {
                                                        _submitCode(context);
                                                      }
                                                    },
                                                    child: Container(
                                                      width: 60.h,
                                                      height: 60.h,
                                                      decoration: BoxDecoration(
                                                        color: context.colors.primary,
                                                        borderRadius: BorderRadius.circular(100.r),
                                                      ),
                                                      child: Padding(
                                                        padding: EdgeInsets.symmetric(vertical: 20.h),
                                                        child: MyIcon(
                                                          'assets/icons/arrow_right.svg',
                                                          size: 20.h,
                                                          color: context.colors.secondaryTextColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : const SizedBox(),
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
