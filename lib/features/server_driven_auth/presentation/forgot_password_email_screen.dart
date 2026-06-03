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

/// Scenario 5 entry — single email field + Send code. Reached only from the
/// `LoginPasswordRequired` inline state (FR-SDA-12).
class ForgotPasswordEmailScreen extends StatelessWidget {
  const ForgotPasswordEmailScreen({super.key});

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
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reactions = SdaScreenReactions(di<AuthActionDispatcher>());
    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationKeys.sda_forgot_email_title.tr(context)),
      ),
      body: SafeArea(
        child: BlocConsumer<ServerDrivenAuthCubit, ServerDrivenAuthState>(
          listener: reactions.onState,
          builder: (context, state) {
            final isLoading = state is SdaLoading;
            return Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText:
                          LocalizationKeys.sda_forgot_email_hint.tr(context),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  SdaPrimaryButton(
                    isLoading: isLoading,
                    label: LocalizationKeys.sda_send_code_cta.tr(context),
                    onPressed: () => context
                        .read<ServerDrivenAuthCubit>()
                        .forgotPassword(_email.text.trim()),
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
