import 'package:escola/core/components/dialogs/dialogs_functions.dart';
import 'package:escola/core/components/widgets/app_bar.dart';
import 'package:escola/core/config/config.dart';
import 'package:escola/core/config/widgets/config_builder.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/models/user_model.dart';
import 'package:escola/core/user/bloc/user_bloc.dart';
import 'package:escola/core/user/widgets/user_builder.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/funuctions/global_functions.dart';
import 'package:escola/core/utils/funuctions/widget_functions.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/all_children/presentation/all_children_screen.dart';
import 'package:escola/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:escola/features/chat/presentation/contacts_screen.dart';
import 'package:escola/features/chat/presentation/professor_contacts.dart';
import 'package:escola/features/choose_language/presentation/choose_language_screen.dart';
import 'package:escola/features/gallery/gallery_screen.dart';
import 'package:escola/features/home/widgets/children_menus.dart';
import 'package:escola/features/login/presentation/login_screen.dart';
import 'package:escola/features/main/bloc/main_bloc.dart';
import 'package:escola/features/my_addresses/my_addresses_screen.dart';
import 'package:escola/features/onboard/presentation/onboard_screen.dart';
import 'package:escola/features/settings/about/about_screen.dart';
import 'package:escola/features/settings/edit_profile/edit_profile_screen.dart';
import 'package:escola/features/settings/medicines/medicine_screen.dart';
import 'package:escola/features/settings/medicines_professors/medicine_professors_screen.dart';
import 'package:escola/features/settings/my_children/my_children_screen.dart';
import 'package:escola/features/settings/widgets/complete_profile_card.dart';
import 'package:escola/features/settings/widgets/settings_item.dart';
import 'package:escola/features/terms_and_condtions/terms_and_conditions_screen.dart';
import 'package:escola/flavors/app_flavors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final unReadMessages = context.watch<ChatBloc>().unReadMessagesCount;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: UserListener(
        listenWhen: compareStates([(s) => s.user != null]),
        listener: (context, state) {
          if (state.user == null) {
            context.read<MainBloc>().add(ChangePage(id: PageID.home.name));
          ChooseLanguageScreen.push(context);
          }
        },
        child: SafeArea(
            top: false,
            child: Column(
              children: [
                MyAppBar(title: LocalizationKeys.settings.tr(context)),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        UserSelector(
                          selector: (state) => state.user,
                          builder: (context, user) => Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (user?.completedProfile() == false)
                                CompleteProfileCard(percentage: user!.getPercentage()),
                            ],
                          ),
                        ),
                        SettingsItem(
                          iconPath: assetsPath('edit_profile'),
                          title: LocalizationKeys.my_information.tr(context),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfileScreen(),
                              ),
                            );
                          },
                        ),
                        // if (context.isParents)
                        //   SettingsItem(
                        //     iconPath: 'assets/icons/map.svg',
                        //     title: LocalizationKeys.add_address.tr(context),
                        //     onTap: () {
                        //       Navigator.push(
                        //         context,
                        //         MaterialPageRoute(
                        //           builder: (context) => const AddAddressScreen(),
                        //         ),
                        //       );
                        //     },
                        //   ),
                        // if (context.isParents)
                        SettingsItem(
                          iconPath: assetsPath('map'),
                          title: LocalizationKeys.my_addresses.tr(context),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MyAddressesScreen(),
                              ),
                            );
                          },
                        ),
                        if (context.isParents)
                          SettingsItem(
                            iconPath: assetsPath('child'),
                            title: LocalizationKeys.my_children.tr(context),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MyChildrenScreen(),
                                ),
                              );
                            },
                          ),
                        if (context.isParents)
                          SettingsItem(
                            iconPath: assetsPath('menu_icon'),
                            title: LocalizationKeys.menus.tr(context),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ChildrenMenusScreen(),
                                ),
                              );
                            },
                          ),
                        if (context.isProfessors)
                          SettingsItem(
                            iconPath: assetsPath('child'),
                            title: LocalizationKeys.all_children.tr(context),
                            hasNotifications: false,
                            // iconColor: context.colors.primary,
                            onTap: () {
                              WidgetFunctions.navigateTo(context, const AllChildrenScreen());
                            },
                          ),
                        if(false)
                        if (context.isParents)
                          SettingsItem(
                            iconPath: assetsPath('gallery'),
                            title: LocalizationKeys.gallery.tr(context),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const GalleryScreen(),
                                ),
                              );
                            },
                          ),
                        SettingsItem(
                          iconPath: assetsPath('medicine'),
                          title: LocalizationKeys.medicines.tr(context),
                          onTap: () {
                            if (context.isParents) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MedicinesScreen(),
                                ),
                              );
                            } else if (context.isProfessors) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MedicinesProfessorsScreen(),
                                ),
                              );
                            }
                          },
                        ),
                        // SettingsItem(
                        //   iconPath: 'assets/icons/event.svg',
                        //   title: LocalizationKeys.events.tr(context),
                        //   onTap: () {
                        //     Navigator.push(
                        //       context,
                        //       MaterialPageRoute(
                        //         builder: (context) => const EventsScreen(),
                        //       ),
                        //     );
                        //   },
                        // ),
                        SettingsItem(
                            iconPath: assetsPath('chat'),
                            title: LocalizationKeys.my_conversations.tr(context),
                            hasNotifications: unReadMessages != 0,
                            notificationNumber: unReadMessages,
                            notificationTextColor: Colors.white,
                            notificationBackgroundColor: Colors.red,
                            onTap: () => goToContactsScreen(context)),
                        SettingsItem(
                          iconPath: assetsPath('support'),
                          title: LocalizationKeys.about.tr(context),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
                          },
                        ),
                        if(Config.get.langs.length >1)
                        SettingsItem(
                          iconPath: assetsPath('language'),
                          title: LocalizationKeys.change_language.tr(context),
                          onTap: () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const ChooseLanguageScreen(fromSettings: true)));
                          },
                        ),
                        SettingsItem(
                          iconPath: assetsPath('terms'),
                          title: LocalizationKeys.terms_and_conditions.tr(context),
                          hasNotifications: false,
                          notificationNumber: 12,
                          notificationBackgroundColor: context.colors.alert,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsAndConditions()));
                            //
                          },
                        ),
                        SettingsItem(
                          iconPath: assetsPath('logout'),
                          title: LocalizationKeys.logout.tr(context),
                          onTap: () {
                            UserBloc.get.loggedOut();
                          },
                        ),
                        SizedBox(
                          height: 15.h,
                        ),
                        SettingsItem(
                          iconPath: assetsPath('delete_acc'),
                          title: LocalizationKeys.delete_account.tr(context),
                          iconColor: context.colors.alert,
                          textColor: context.colors.alert,
                          lastIconColor: context.colors.alert,
                          onTap: () async {
                            final b = await confirmDialog(
                              context: context,
                              titleKey: LocalizationKeys.delete_account,
                              bodyKey: LocalizationKeys.delete_account_confirm,
                            );
                            if (b == true) {
                              UserBloc.get.deleteAccount();
                            }
                          },
                        ),
                        Container(
                          height: 10.h,
                          color: context.colors.background,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )),
      ),
    );
  }
}

void goToContactsScreen(BuildContext context) {
  final userType = context.read<ChatBloc>().currentUser?.type;
  final bool isProfessor = userType == UserType.professor && context.isProfessors;
  WidgetFunctions.navigateTo(
    context,
    isProfessor ? const ProfessorsContacts() : const ContactsScreen(),
  );
}
