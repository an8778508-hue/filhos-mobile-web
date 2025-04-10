import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/local_db/local_db_repo.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/features/diary/data_sources/diary_impl.dart';
import 'package:escola/features/diary/data_sources/diary_repo.dart';
import 'package:escola/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:escola/features/search/data_sources/search_dc.dart';

class DiaryInjection implements DependencyInjection {
  @override
  void init() {
    // Data sources
    di.registerFactory<DiaryRepo>(() => di<DiaryImpl>());
    di.registerFactory<DiaryImpl>(
        () => DiaryImpl(networkClient: di<NetworkClientRepository>()));
    // Bloc
    di.registerFactory<DiaryBloc>(() => DiaryBloc(
          diaryRepo: di<DiaryRepo>(),
          searchRepo: di<SearchRepo>(),
          localDatabaseRepo: di<LocalDatabaseRepo>(),
        ));
  }
}
