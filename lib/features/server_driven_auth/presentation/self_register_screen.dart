import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/features/server_driven_auth/dispatcher/auth_action_dispatcher.dart';
import 'package:escola/features/server_driven_auth/presentation/bloc/server_driven_auth_cubit.dart';
import 'package:escola/features/server_driven_auth/presentation/bloc/server_driven_auth_state.dart';
import 'package:escola/features/server_driven_auth/presentation/widgets/sda_button.dart';
import 'package:escola/features/server_driven_auth/presentation/widgets/sda_listener_mixin.dart';
import 'package:escola/flavors/app_flavors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Scenario 2 — self-registration. Calls `POST auth/self-register`; the server
/// branches on `EMAIL_OTP_ENABLED` and returns either `VERIFY_EMAIL_OTP`
/// (→ EmailOtpScreen) or `GO_TO_PENDING_APPROVAL` (→ PendingApprovalScreen).
/// Mobile is unaware of the flag.
class SelfRegisterScreen extends StatelessWidget {
  const SelfRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ServerDrivenAuthCubit>(
      create: (_) => di<ServerDrivenAuthCubit>(),
      child: const _Body(),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final String _countryCode = '+55';

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reactions = SdaScreenReactions(di<AuthActionDispatcher>());

    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationKeys.sda_register_title.tr(context)),
      ),
      body: SafeArea(
        child: BlocConsumer<ServerDrivenAuthCubit, ServerDrivenAuthState>(
          listener: reactions.onState,
          builder: (context, state) {
            final isLoading = state is SdaLoading;
            return SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _field(
                    controller: _name,
                    label: LocalizationKeys.sda_register_name_label.tr(context),
                  ),
                  _field(
                    controller: _phone,
                    label: LocalizationKeys.sda_phone_label.tr(context),
                    keyboard: TextInputType.phone,
                    prefix: '$_countryCode  ',
                  ),
                  _field(
                    controller: _email,
                    label:
                        LocalizationKeys.sda_register_email_label.tr(context),
                    keyboard: TextInputType.emailAddress,
                  ),
                  _field(
                    controller: _password,
                    label: LocalizationKeys.sda_password_label.tr(context),
                    obscure: true,
                  ),
                  _field(
                    controller: _confirm,
                    label: LocalizationKeys.sda_confirm_password_label
                        .tr(context),
                    obscure: true,
                  ),
                  SizedBox(height: 16.h),
                  SdaPrimaryButton(
                    isLoading: isLoading,
                    label: LocalizationKeys.sda_register_title.tr(context),
                    onPressed: () =>
                        context.read<ServerDrivenAuthCubit>().selfRegister(
                              name: _name.text.trim(),
                              phone: _phone.text.trim(),
                              countryCode: _countryCode,
                              email: _email.text.trim(),
                              password: _password.text,
                              passwordConfirmation: _confirm.text,
                              role: context.isProfessors ? 'teacher' : 'parent',
                            ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    bool obscure = false,
    TextInputType? keyboard,
    String? prefix,
  }) {
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: 12.h),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefix,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
