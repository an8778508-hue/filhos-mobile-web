import 'package:escola/core/components/fields/custom_text_field.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/login/presentation/bloc/login_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EmailOTPTab extends StatefulWidget {
  const EmailOTPTab({
    super.key,
    required this.emailController,
    required this.formKey,
  });

  final TextEditingController emailController;
  final GlobalKey<FormState> formKey;

  @override
  State<EmailOTPTab> createState() => _EmailOTPTabState();
}

class _EmailOTPTabState extends State<EmailOTPTab> {
  bool _isFormatValid = false;

  static final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  void _onChanged(String value) {
    final valid = _emailRegex.hasMatch(value.trim());
    if (valid != _isFormatValid) {
      setState(() => _isFormatValid = valid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('email_otp_form'),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 42.csw),
            child: CustomTextField(
              controller: widget.emailController,
              hint: LocalizationKeys.email_otp_email_placeholder.tr(context),
              backgroundColor: context.colors.background,
              padding: EdgeInsets.symmetric(vertical: 5.csh, horizontal: 20.csw),
              borderRadius: 30.r,
              keyboardType: TextInputType.emailAddress,
              onChanged: _onChanged,
              validator: (value) {
                if (!validString(value)) {
                  return LocalizationKeys.this_field_cant_be_empty.tr(context);
                }
                if (!_emailRegex.hasMatch(value!.trim())) {
                  return LocalizationKeys.email_otp_error_invalid_format.tr(context);
                }
                return null;
              },
            ),
          ),
          SizedBox(height: 20.csh),
          BlocSelector<LoginBloc, LoginState, bool>(
            selector: (state) => state is LoginLoading,
            builder: (context, loading) => GestureDetector(
              onTap: _isFormatValid && !loading
                  ? () {
                      widget.formKey.currentState?.save();
                      if (widget.formKey.currentState?.validate() ?? false) {
                        BlocProvider.of<LoginBloc>(context).requestEmailOTP(
                          email: widget.emailController.text.trim(),
                        );
                      }
                    }
                  : null,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 40.w),
                padding: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  color: _isFormatValid
                      ? context.colors.primary
                      : context.colors.primary.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(30.r),
                ),
                alignment: Alignment.center,
                child: loading
                    ? SizedBox(
                        height: 24.h,
                        width: 24.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.colors.secondaryTextColor,
                        ),
                      )
                    : Text(
                        LocalizationKeys.email_otp_send_cta.tr(context),
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w500,
                          color: context.colors.secondaryTextColor,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
