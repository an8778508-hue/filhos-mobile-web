import 'package:escola/core/components/custom_reactions/src/models/reaction.dart';
import 'package:escola/shared/assets/assets.gen.dart';
import 'package:flutter/material.dart';

import 'reaction_icons.dart';

enum MyReaction{
  like,
  love,
  haha,
  care,
  wow,
  sad,
  angry,
}

sealed class MyReactions {
  final MyReaction value;
  final String iconPath;

  const MyReactions({
    required this.value,
    required this.iconPath,
  });

  Widget get icon => ReactionIcon(iconPath: iconPath, value: value);

  Widget get preview => ReactionPreview(iconPath: iconPath);

  Reaction<MyReaction> get reaction => Reaction<MyReaction>(
    value: value,
    icon: icon,
    previewIcon: preview,
  );
}

class LikeReaction extends MyReactions {
  LikeReaction()
      : super(
          value: MyReaction.like,
          iconPath: Assets.icons.like.path,
        );
}

class LoveReaction extends MyReactions {
  LoveReaction()
      : super(
          value: MyReaction.love,
          iconPath: Assets.icons.love.path,
        );
}

class CareReaction extends MyReactions {
  CareReaction()
      : super(
          value: MyReaction.care,
          iconPath: Assets.icons.care.path,
        );
}

class HahaReaction extends MyReactions {
  HahaReaction()
      : super(
          value: MyReaction.haha,
          iconPath: Assets.icons.haha.path,
        );
}

class WowReaction extends MyReactions {
  WowReaction()
      : super(
          value: MyReaction.wow,
          iconPath: Assets.icons.wow.path,
        );
}

class SadReaction extends MyReactions {
  SadReaction()
      : super(
          value: MyReaction.sad,
          iconPath: Assets.icons.sad.path,
        );
}

class AngryReaction extends MyReactions {
  AngryReaction()
      : super(
          value: MyReaction.angry,
          iconPath: Assets.icons.angry.path,
        );
}

final List<MyReactions> reactionsIcons = [
  LikeReaction(),
  LoveReaction(),
  CareReaction(),
  HahaReaction(),
  WowReaction(),
  // SadReaction(),
  // AngryReaction(),
];
