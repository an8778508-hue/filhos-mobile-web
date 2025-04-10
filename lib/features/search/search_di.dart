import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/features/search/bloc/search_bloc.dart';
import 'package:escola/features/search/data_sources/search_dc.dart';

class SearchInjecion implements DependencyInjection {
  @override
  void init() {
    // Data sources
    di.registerFactory<SearchRepo>(() => di<SearchImpl>());
    di.registerFactory<SearchImpl>(
        () => SearchImpl(networkClient: di<NetworkClientRepository>()));
    // Bloc
    di.registerFactory<SearchBloc>(() => SearchBloc(di<SearchRepo>()));
  }
}
