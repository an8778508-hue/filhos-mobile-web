import 'package:flutter/foundation.dart';

@immutable
abstract class MedicinesEvents {
  const MedicinesEvents();
}

class FetchMedicines extends MedicinesEvents {
  const FetchMedicines();
}

class DeleteMedicine extends MedicinesEvents {
  final String id;
  const DeleteMedicine(this.id);
}

class LoadMoreMedicines extends MedicinesEvents {
  const LoadMoreMedicines();
}

class SubmitMedicinesEvent extends MedicinesEvents {}
