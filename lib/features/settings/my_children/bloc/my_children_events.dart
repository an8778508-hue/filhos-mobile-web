import 'package:flutter/foundation.dart';

@immutable
abstract class MyChildrenEvents {
  const MyChildrenEvents();
}

class FetchMyChildren extends MyChildrenEvents {
  final int page;
  const FetchMyChildren(this.page);
}

class SubmitMyChildrenEvent extends MyChildrenEvents {}
