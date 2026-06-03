import 'dart:async';

import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/features/server_driven_auth/dispatcher/auth_action_dispatcher.dart';
import 'package:escola/features/server_driven_auth/presentation/bloc/server_driven_auth_cubit.dart';
import 'package:escola/features/server_driven_auth/presentation/bloc/server_driven_auth_state.dart';
import 'package:escola/features/server_driven_auth/presentation/widgets/sda_button.dart';
import 'package:escola/features/server_driven_auth/presentation/widgets/sda_listener_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

/// Scenario 2 — registration OTP. Distinct from [ResetOtpScreen] (FR-SDA-09)
/// even though both wrap the same pin widget — copy and back behavior differ.
class EmailOtpScreen extends StatelessWidget {
  final String tempToken;
  const EmailOtpScreen({super.key, required this.tempToken});

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
  final _codeCtrl = TextEditingController();
  Timer? _timer;
  int _secondsLeft = 60;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeCtrl.dispose();
    super.dispose();
  }

  /// 60-second resend cooldown per FR-SDA-10. Server enforces too — the local
  /// timer is for UX only; on `OTP_EXPIRED` the cubit clears it (not modeled
  /// here for brevity; the screen-level resend re-runs the originating flow).
  void _startResendTimer() {
    _secondsLeft = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) t.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reactions = SdaScreenReactions(di<AuthActionDispatcher>());
    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationKeys.sda_email_otp_title.tr(context)),
      ),
      body: SafeArea(
        child: BlocConsumer<ServerDrivenAuthCubit, ServerDrivenAuthState>(
          listener: (context, state) {
            reactions.onState(context, state);
            // Clear the pin so the user (and Playwright) can immediately type
            // a new code after an OTP_INVALID failure. Backspace on the
            // hidden TextField alone doesn't sync pin_code_fields' internal
            // cell list — clearing the controller does both at once.
            if (state is SdaFailure) {
              _codeCtrl.clear();
            }
          },
          builder: (context, state) {
            final isLoading = state is SdaLoading;
            return Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 12.h),
                  Text(
                    LocalizationKeys.sda_email_otp_subline.tr(context),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  PinCodeTextField(
                    appContext: context,
                    length: 6,
                    controller: _codeCtrl,
                    keyboardType: TextInputType.number,
                    // autoFocus so users (and Playwright) can type immediately
                    // without first tapping a cell — pin_code_fields hides its
                    // real TextField behind 6 tappable cells, and on Flutter
                    // Web the cells (exposed as buttons) intercept clicks on
                    // the underlying input. autoFocus sidesteps the issue.
                    autoFocus: true,
                    onChanged: (_) {},
                    onCompleted: (code) =>
                        context.read<ServerDrivenAuthCubit>().verifyEmailOtp(
                              tempToken: widget.tempToken,
                              code: code,
                            ),
                  ),
                  SizedBox(height: 12.h),
                  if (_secondsLeft > 0)
                    Text(
                      LocalizationKeys.sda_resend_in
                          .tr(context)
                          .replaceAll('{seconds}', _secondsLeft.toString()),
                      textAlign: TextAlign.center,
                    )
                  else
                    SdaPrimaryButton(
                      isLoading: isLoading,
                      fullWidth: false,
                      label: LocalizationKeys.sda_resend_cta.tr(context),
                      onPressed: () {
                        // Resend = pop back to the originating screen so the
                        // user can re-trigger self-register / forgot-password.
                        // V1: the screen restarts the local cooldown; the
                        // server-side re-dispatch is the originating screen's
                        // responsibility.
                        _startResendTimer();
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
