import 'package:flutter/foundation.dart';

@immutable
abstract class MedicinesProfessorsEvents {
  const MedicinesProfessorsEvents();
}

class FetchMedicinesProfessors extends MedicinesProfessorsEvents {
  const FetchMedicinesProfessors();
}

class AcceptMedicinesProfessors extends MedicinesProfessorsEvents {
  const AcceptMedicinesProfessors();
}

class DeclineMedicinesProfessors extends MedicinesProfessorsEvents {
  const DeclineMedicinesProfessors();
}
