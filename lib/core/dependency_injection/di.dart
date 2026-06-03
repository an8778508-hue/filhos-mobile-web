import 'dart:async';

import 'package:escola/core/config/cubit/cubit.dart';
import 'package:escola/core/dependency_injection/network_injection.dart';
import 'package:escola/core/local_db/local_db_impl.dart';
import 'package:escola/core/local_db/local_db_repo.dart';
import 'package:escola/core/network/network_client.dart';
import 'package:escola/core/user/user_di.dart';
import 'package:escola/core/utils/alarm_manager/alarm_manager.dart';
import 'package:escola/core/utils/alarm_manager/alarm_repo.dart';
import 'package:escola/features/add_address/bloc/add_address_bloc.dart';
import 'package:escola/features/add_address/repo/add_address_repo.dart';
import 'package:escola/features/add_form/add_form_screen.dart';
import 'package:escola/features/add_form/bloc/add_form_bloc.dart';
import 'package:escola/features/add_form/repo/add_form_repo.dart';
import 'package:escola/features/add_medicine/repo/add_medicine_repo.dart';
import 'package:escola/features/all_children/all_children_di.dart';
import 'package:escola/features/background_services/background_services_di.dart';
import 'package:escola/features/chat/chat_di.dart';
import 'package:escola/features/diary/diary_di.dart';
import 'package:escola/features/featured_events/bloc/featured_events_bloc.dart';
import 'package:escola/features/gallery/bloc/gallery_bloc.dart';
import 'package:escola/features/gallery/repo/gallery_repo.dart';
import 'package:escola/features/gallery_images/bloc/gallery_images_bloc.dart';
import 'package:escola/features/home/data_source/home_di.dart';
import 'package:escola/features/login/login_di.dart';
import 'package:escola/features/my_addresses/bloc/my_addresses_bloc.dart';
import 'package:escola/features/my_addresses/repo/my_addresses_repo.dart';
import 'package:escola/features/notifications/bloc/notifications_bloc.dart';
import 'package:escola/features/notifications/repo/notifications_repo.dart';
import 'package:escola/features/otp/presentation/bloc/otp_bloc.dart';
import 'package:escola/features/search/search_di.dart';
import 'package:escola/features/server_driven_auth/server_driven_auth_di.dart';
import 'package:escola/features/search_for_filter/bloc/search_for_filter_bloc.dart';
import 'package:escola/features/settings/about/bloc/about_bloc.dart';
import 'package:escola/features/settings/about/repo/about_repo.dart';
import 'package:escola/features/settings/accept_event/data_source/single_event_di.dart';
import 'package:escola/features/settings/announcements/data_source/announcements_di.dart';
import 'package:escola/features/settings/edit_profile/bloc/edit_profile_bloc.dart';
import 'package:escola/features/settings/edit_profile/repo/edit_profile_repo.dart';
import 'package:escola/features/settings/events/data_source/events_di.dart';
import 'package:escola/features/settings/medicines/bloc/medicines_bloc.dart';
import 'package:escola/features/settings/medicines/repo/medicines_repo.dart';
import 'package:escola/features/settings/medicines_professors/data_source/medicine_professors_di.dart';
import 'package:escola/features/settings/my_children/bloc/my_children_bloc.dart';
import 'package:escola/features/settings/my_children/repo/my_children_repo.dart';
import 'package:escola/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:escola/features/terms_and_condtions/bloc/terms_bloc.dart';
import 'package:escola/features/terms_and_condtions/repo/terms_repo.dart';
import 'package:get_it/get_it.dart';

final di = GetIt.instance;

abstract class DependencyInjection {
  void init();
}

FutureOr dependencyInjection() async {
  // config
  final configCubit = ConfigCubit();
  await configCubit.init();
  di.registerSingleton(configCubit);

  // repos
  di.registerFactory<LocalDatabaseRepo>(() => LocalDatabaseImpl());
  NetworkInjection().init();

  di.registerSingleton(AddressesRepo(di<NetworkClientRepository>()));
  di.registerSingleton(MyAddressesRepo(networkClient: di<NetworkClientRepository>()));
  di.registerSingleton(MedicinesRepo(di()));
  di.registerSingleton(EditProfileRepo(networkClientRepository: di<NetworkClientRepository>()));
  di.registerSingleton(MyChildrenRepo(networkClient: di<NetworkClientRepository>()));
  di.registerSingleton(AboutRepo(networkClient: di<NetworkClientRepository>()));
  di.registerSingleton(NotificationsRepo(networkClient: di<NetworkClientRepository>()));
  di.registerSingleton(AlarmRepo(di<NetworkClientRepository>()));
  di.registerSingleton(AlarmManager(di<AlarmRepo>()));
  for (final formType in AddFormType.values) {
    di.registerSingleton(AddFormRepo(formType, di<NetworkClientRepository>(), di<MyChildrenRepo>()),
        instanceName: formType.name);
  }
  di.registerSingleton(
    AddMedicineRepo(AddFormType.medicine, di<NetworkClientRepository>(), di<MyChildrenRepo>()),
  );
  // blocs

  di.registerFactory<SplashBloc>(() => SplashBloc(di(), di()));
  di.registerFactory<SearchForFilterBloc>(() => SearchForFilterBloc(di(), di()));
  di.registerFactory<OTPBloc>(() => OTPBloc(di(), di()));
  for (final formType in AddFormType.values) {
    di.registerFactory<AddFormBloc>(() => AddFormBloc(di<AddFormRepo>(instanceName: formType.name), formType,di<MyChildrenRepo>(),di<AddMedicineRepo>()),
        instanceName: formType.name);
  }

  di.registerFactory<AddAddressBloc>(() => AddAddressBloc(
        addressesRepo: di(),
      ));
  di.registerFactory<MyAddressesBloc>(() => MyAddressesBloc(
        myAddressesRepo: di(),
      ));
  di.registerFactory<MyChildrenBloc>(() => MyChildrenBloc(
        myMyChildrenRepo: di(),
      ));
  di.registerFactory<MedicinesBloc>(() => MedicinesBloc(
        medicinesRepo: di(),
      ));
  di.registerFactory<AboutBloc>(() => AboutBloc(myAboutRepo: di()));
  di.registerFactory<EditProfileBloc>(() => EditProfileBloc(editProfileRepo: di<EditProfileRepo>()));
  di.registerFactory<NotificationsBloc>(() => NotificationsBloc(notificationsRepo: di<NotificationsRepo>()));

  //features
  UserInjection().init();
  LoginInjection().init();
  // Server-driven auth ships dark behind `Config.serverDrivenAuthEnabled`
  // (default false). Registering its DI is safe even when the flag is off —
  // factories are lazy and nothing is constructed until a screen opens.
  ServerDrivenAuthInjection().init();
  DiaryInjection().init();
  ChatInjection().init();
  BackgroundServicesInjection().init();
  HomeInjection().init();
  AnnouncementsInjection().init();
  MedicinesProfessorsInjection().init();
  SearchInjecion().init();

  AllChildrenInjection().init();
  EventsInjection().init();
  SingleEventInjection().init();
  di.registerSingleton(TermsRepo(networkClient: di()));
  di.registerFactory(() => TermsBloc(myTermsRepo: di()));
  di.registerFactory(() => FeaturedEventsBloc(di()));
  di.registerSingleton(GalleryRepo(networkClient: di()));
  di.registerFactory(() => GalleryBloc(di()));
  di.registerFactory(() => GalleryImagesBloc(di()));
}
