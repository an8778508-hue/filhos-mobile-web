import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/features/server_driven_auth/dispatcher/auth_action_dispatcher.dart';
import 'package:escola/features/server_driven_auth/presentation/bloc/server_driven_auth_cubit.dart';
import 'package:escola/features/server_driven_auth/presentation/bloc/server_driven_auth_state.dart';
import 'package:escola/features/server_driven_auth/presentation/forgot_password_email_screen.dart';
import 'package:escola/features/server_driven_auth/presentation/self_register_screen.dart';
import 'package:escola/features/server_driven_auth/presentation/widgets/sda_button.dart';
import 'package:escola/features/server_driven_auth/presentation/widgets/sda_listener_mixin.dart';
import 'package:escola/flavors/app_flavors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Scenarios 1, 3, 4, and the entry to Scenarios 2 and 5.
///
/// One screen, one cubit. The password field appears INLINE on
/// `SdaLoginPasswordRequired` (FR-SDA-04, FR-SDA-12) — there is no navigation
/// on `REQUIRE_PASSWORD`, the screen rebuilds. The "Forgot password?" control
/// appears next to the password field only while that state is active.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ServerDrivenAuthCubit>(
      create: (_) => di<ServerDrivenAuthCubit>(),
      child: const _LoginScreenBody(),
    );
  }
}

class _LoginScreenBody extends StatefulWidget {
  const _LoginScreenBody();

  @override
  State<_LoginScreenBody> createState() => _LoginScreenBodyState();
}

class _LoginScreenBodyState extends State<_LoginScreenBody> {
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  // Brazilian default; matches existing LoginScreen behavior.
  final String _countryCode = '+55';

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String get _role => context.isProfessors ? 'teacher' : 'parent';

  void _onNext(BuildContext context) {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) return;
    context.read<ServerDrivenAuthCubit>().checkIdentifier(
          phone: phone,
          countryCode: _countryCode,
          role: _role,
        );
  }

  void _onLogin(BuildContext context, String phone, String countryCode) {
    final password = _passwordCtrl.text;
    context.read<ServerDrivenAuthCubit>().login(
          phone: phone,
          countryCode: countryCode,
          password: password,
          role: _role,
        );
  }

  @override
  Widget build(BuildContext context) {
    final reactions = SdaScreenReactions(di<AuthActionDispatcher>());

    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationKeys.login.tr(context)),
      ),
      body: SafeArea(
        child: BlocConsumer<ServerDrivenAuthCubit, ServerDrivenAuthState>(
          listener: reactions.onState,
          builder: (context, state) {
            final isPasswordRequired = state is SdaLoginPasswordRequired;
            final isLoading = state is SdaLoading;
            final isNotFound = state is SdaPhoneNotFound;
            final isSuspended = state is SdaAccountSuspended;

            return SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── Phone field (always visible) ───
                  TextField(
                    controller: _phoneCtrl,
                    enabled: !isPasswordRequired,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: LocalizationKeys.sda_phone_label.tr(context),
                      prefixText: '$_countryCode  ',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ─── Inline password field (state-driven, no nav) ───
                  if (isPasswordRequired) ...[
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: true,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText:
                            LocalizationKeys.sda_password_label.tr(context),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    // Inline "Forgot password?" — appears ONLY in this state
                    // (FR-SDA-12).
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: isLoading
                            ? null
                            : () => Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) =>
                                      const ForgotPasswordEmailScreen(),
                                )),
                        child: Text(
                          LocalizationKeys.sda_forgot_password_cta.tr(context),
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    SdaPrimaryButton(
                      isLoading: isLoading,
                      label: LocalizationKeys.sda_login_cta.tr(context),
                      onPressed: () => _onLogin(
                        context,
                        state.phone,
                        state.countryCode,
                      ),
                    ),
                  ] else ...[
                    SdaPrimaryButton(
                      isLoading: isLoading,
                      label: LocalizationKeys.sda_next_cta.tr(context),
                      onPressed: () => _onNext(context),
                    ),
                  ],

                  // ─── Inline informational rows for NOT_FOUND / SUSPENDED ───
                  if (isNotFound) ...[
                    SizedBox(height: 24.h),
                    Text(
                      LocalizationKeys.sda_no_account_prompt.tr(context),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    SdaPrimaryButton(
                      label: LocalizationKeys.sda_create_account_link
                          .tr(context),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SelfRegisterScreen(),
                        ),
                      ),
                    ),
                  ],
                  if (isSuspended) ...[
                    SizedBox(height: 24.h),
                    Text(
                      LocalizationKeys.sda_error_account_suspended.tr(context),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],

                  // ─── Create new account link (always visible at the bottom) ───
                  SizedBox(height: 32.h),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SelfRegisterScreen(),
                      ),
                    ),
                    child: Text(
                      LocalizationKeys.sda_create_account_link.tr(context),
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
}
