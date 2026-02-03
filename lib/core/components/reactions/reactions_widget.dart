import 'package:escola/core/components/custom_reactions/src/widgets/reaction_button.dart';
import 'package:escola/core/components/snack.dart';
import 'package:escola/core/config/widgets/config_builder.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/safe_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'bloc/reactions_bloc.dart';
import 'bloc/reactions_state.dart';
import 'reactions.dart';

class Reactions extends StatelessWidget {
  const Reactions({
    super.key,
    this.count = 0,
    this.myReaction,
  });

  final int count;
  final MyReaction? myReaction;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReactionsBloc(count, myReaction),
      child: MultiBlocListener(
        listeners: [
          BlocListener<ReactionsBloc, ReactionsState>(
            listenWhen: compareStates([(s) => s.failure]),
            listener: (context, state) {
              if (state.failure != null) {
                Snack.show(context, LocalizationKeys.server_error.tr(context), false);
              }
            },
          ),
          BlocListener<ReactionsBloc, ReactionsState>(
            listenWhen: compareStates([(s) => s.myReaction]),
            listener: (context, state) {
              Snack.show(context, LocalizationKeys.success_action.tr(context), true);
            },
          ),
        ],
        child: BlocBuilder<ReactionsBloc, ReactionsState>(
          builder: (context, state) {
            return ReactionButton<MyReaction>(
              itemSize: Size(40.w, 40.w),
              toggle: false,
              onReactionChanged: (reaction) {
                debugPrint('SELECTED REACTION: ${reaction?.value}');
                if (reaction?.value != null) {
                  if (reaction?.value != state.getMyReaction) {
                    BlocProvider.of<ReactionsBloc>(context).sendReaction(reaction!.value!);
                  } else {
                    BlocProvider.of<ReactionsBloc>(context).sendReaction(null);
                  }
                }
              },
              selectedReaction:
                  (reactionsIcons.safeFirstWhere((r) => r.value == state.getMyReaction) ?? LikeReaction()).reaction,
              reactions: [
                ...reactionsIcons.map(
                  (e) => e.reaction,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
