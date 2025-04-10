import 'package:escola/features/add_address/models/city_model.dart';
import 'package:escola/features/add_address/models/area_model.dart';
import 'package:escola/features/add_address/models/region_model.dart';
import 'package:flutter/foundation.dart';

@immutable
abstract class TermsEvents {
  const TermsEvents();
}

class FetchTerms extends TermsEvents {
  const FetchTerms();
}


class FetchPrivacy extends TermsEvents {
  const FetchPrivacy();
}

