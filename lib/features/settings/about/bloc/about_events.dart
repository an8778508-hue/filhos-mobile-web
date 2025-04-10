import 'package:escola/features/add_address/models/city_model.dart';
import 'package:escola/features/add_address/models/area_model.dart';
import 'package:escola/features/add_address/models/region_model.dart';
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
