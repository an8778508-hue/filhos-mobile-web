import 'package:escola/core/components/loading/loading_overlay.dart';
import 'package:escola/core/components/text/text_html.dart';
import 'package:escola/core/components/widgets/app_bar.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/features/terms_and_condtions/bloc/terms_bloc.dart';
import 'package:escola/features/terms_and_condtions/bloc/terms_events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

import 'bloc/terms_states.dart';

class TermsAndConditions extends StatelessWidget {
  const TermsAndConditions({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di<TermsBloc>()..add(const FetchTerms()),
      child: Scaffold(
        appBar: MyAppBar(
          title: (LocalizationKeys.terms_and_conditions).tr(context),
          hasNotification: false,
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.all(10.h),
              child: BlocBuilder<TermsBloc, TermsStates>(
                builder: (context, state) => TextHtml(
                  state.aboutState.data ?? '',
                ),
              ),
            ),
            BlocBuilder<TermsBloc, TermsStates>(
              builder: (context, state) => state.aboutState.loading ? const LoadingOverlay() : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}
