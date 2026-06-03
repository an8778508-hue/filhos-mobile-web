import 'dart:async';

import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/features/server_driven_auth/dispatcher/auth_action_dispatcher.dart';
import 'package:escola/features/server_driven_auth/presentation/bloc/server_driven_auth_cubit.dart';
import 'package:escola/features/server_driven_auth/presentation/bloc/server_driven_auth_state.dart';
import 'package:escola/features/server_driven_auth/presentation/widgets/sda_listener_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

/// Scenario 5 step 2 — reset OTP. Distinct from [EmailOtpScreen] (FR-SDA-09).
/// On success, `verify-reset-otp` returns `SET_NEW_PASSWORD` and the
/// dispatcher routes to `SetNewPasswordScreen`.
class ResetOtpScreen extends StatelessWidget {
  final String tempToken;
  const ResetOtpScreen({super.key, required this.tempToken});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ServerDrivenAuthCubit>(
      create: (_) => di<ServerDrivenAuthCubit>(),
      child: _Body(tempToken: tempToken),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.tempToken});
  final String tempToken;
  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _ctrl = TextEditingController();
  Timer? _timer;
  int _secondsLeft = 60;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reactions = SdaScreenReactions(di<AuthActionDispatcher>());
    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationKeys.sda_reset_otp_title.tr(context)),
      ),
      body: SafeArea(
        child: BlocListener<ServerDrivenAuthCubit, ServerDrivenAuthState>(
          listener: (context, state) {
            reactions.onState(context, state);
            // See note in email_otp_screen.dart — clear the pin field on
            // failure so a retry can land cleanly.
            if (state is SdaFailure) {
              _ctrl.clear();
            }
          },
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              children: [
                SizedBox(height: 12.h),
                Text(
                  LocalizationKeys.sda_reset_otp_subline.tr(context),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                PinCodeTextField(
                  appContext: context,
                  length: 6,
                  controller: _ctrl,
                  keyboardType: TextInputType.number,
                  // See note in email_otp_screen.dart: autoFocus avoids the
                  // Flutter Web cell-intercepts-input issue.
                  autoFocus: true,
                  onChanged: (_) {},
                  onCompleted: (code) =>
                      context.read<ServerDrivenAuthCubit>().verifyResetOtp(
                            tempToken: widget.tempToken,
                            code: code,
                          ),
                ),
                if (_secondsLeft > 0)
                  Text(LocalizationKeys.sda_resend_in
                      .tr(context)
                      .replaceAll('{seconds}', _secondsLeft.toString())),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
