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

