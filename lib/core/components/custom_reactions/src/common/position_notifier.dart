import 'package:flutter/material.dart';

import 'position.dart';

class PositionNotifier extends ValueNotifier<PositionData> {
  PositionNotifier() : super(const PositionData.init());
}
