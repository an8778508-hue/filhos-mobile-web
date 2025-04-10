import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/features/all_children/data_source/all_children_dc.dart';
import 'package:escola/features/all_children/presentation/bloc/all_children_bloc.dart';

class AllChildrenInjection implements DependencyInjection {
  @override
  void init() {
    // Data sources
    di.registerFactory<AllChildrenRepo>(() => di<AllChildrenImpl>());
    di.registerFactory<AllChildrenImpl>(
        () => AllChildrenImpl(networkClient: di<NetworkClientRepository>()));

    // Bloc
    di.registerFactory<AllChildrenBloc>(
        () => AllChildrenBloc(di<AllChildrenRepo>()));
  }
}
