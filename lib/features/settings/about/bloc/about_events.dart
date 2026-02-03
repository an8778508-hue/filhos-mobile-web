import 'package:flutter/foundation.dart';

@immutable
abstract class AboutEvents {
  const AboutEvents();
}

class FetchAbout extends AboutEvents {
  const FetchAbout();
}

class SubmitAboutEvent extends AboutEvents {
}
