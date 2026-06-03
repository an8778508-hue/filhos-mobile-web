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

/// Scenario 5 terminal — set the new password. Wrapped in
/// `PopScope(canPop: false)` (FR-SDA-07): once the user is past OTP verify,
/// they must commit the new password before leaving. On success the dispatcher
/// clears the stack to LoginScreen and surfaces a success snackbar.
class SetNewPasswordScreen extends StatelessWidget {
  final String tempToken;
  const SetNewPasswordScreen({super.key, required this.tempToken});

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
  final _pw = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _pw.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reactions = SdaScreenReactions(di<AuthActionDispatcher>());
    return PopScope(
      canPop: false, // FR-SDA-07
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title:
              Text(LocalizationKeys.sda_set_new_password_title.tr(context)),
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
                      controller: _pw,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText:
                            LocalizationKeys.sda_password_label.tr(context),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: _confirm,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: LocalizationKeys.sda_confirm_password_label
                            .tr(context),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    SdaPrimaryButton(
                      isLoading: isLoading,
                      label: LocalizationKeys.save.tr(context),
                      onPressed: () =>
                          context.read<ServerDrivenAuthCubit>().resetPassword(
                                tempToken: widget.tempToken,
                                password: _pw.text,
                                passwordConfirmation: _confirm.text,
                              ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
