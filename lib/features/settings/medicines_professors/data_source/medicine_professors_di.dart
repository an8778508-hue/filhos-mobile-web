import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/features/settings/medicines_professors/bloc/medicines_professors_bloc.dart';
import 'package:escola/features/settings/medicines_professors/data_source/medicine_professors_impl.dart';
import 'package:escola/features/settings/medicines_professors/data_source/medicine_professors_repo.dart';

class MedicinesProfessorsInjection implements DependencyInjection {
  @override
  void init() {
    // Data sources
    di.registerSingleton<MedicinesProfessorsRepo>(
        MedicinesProfessorsRepo(networkClient: di<NetworkClientRepository>()));
    // Bloc
    di.registerFactory<MedicinesProfessorsBloc>(
      () => MedicinesProfessorsBloc(
        medicinesProfessorsRepo: di<MedicinesProfessorsRepo>(),
      ),
    );
  }
}
