import 'package:escola/core/config/cubit/cubit.dart';
import 'package:escola/core/config/widgets/config_builder.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/localization/localization_helper.dart';
import 'package:escola/core/theme/custom_theme.dart';
import 'package:escola/core/theme/theme.dart';
import 'package:escola/core/user/widgets/user_builder.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/size_config.dart';
import 'package:escola/features/background_services/bloc/background_services_bloc.dart';
import 'package:escola/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:escola/features/featured_events/bloc/featured_events_bloc.dart';
import 'package:escola/features/main/bloc/main_bloc.dart';
import 'package:escola/features/splash/presentation/splash_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_custom_theme/flutter_custom_theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/user/bloc/user_bloc.dart';
import 'core/user/bloc/user_state.dart';
import 'core/utils/print.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

final mainKey = GlobalKey();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class _MyAppState extends State<MyApp> {
  @override
  void dispose() {
    ConfigCubit.get.close();
    UserBloc.get.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: providers,
      child: Builder(
        builder: (context) => ConfigSelector(
          selector: (config) => config.styling,
          builder: (context, colors) => CustomThemes(
            data: [MyTheme(colors: colors.colors)],
            child: ScreenUtilInit(
              designSize: const Size(430, 932),
              builder: (context, _) => const MaterialAppWidget(),
            ),
          ),
        ),
      ),
    );
  }

  static List<BlocProvider> providers = [
    BlocProvider<MainBloc>(create: (context) => MainBloc()),
    BlocProvider<BackgroundServicesBloc>(create: (context) => di<BackgroundServicesBloc>()),
    BlocProvider<ChatBloc>(create: (context) => di<ChatBloc>()),
    BlocProvider<UserBloc>(create: (context) => di<UserBloc>()),
    BlocProvider<FeaturedEventsBloc>(create: (context) => di<FeaturedEventsBloc>()),
  ];
}

/// Mobile-first canvas on web is now handled by CSS in `web/index.html`
/// (a `@media (min-width: 601px)` rule constrains `flutter-view` to
/// 430×932 with rounded corners + shadow). This means Flutter's
/// `FlutterView` reports the correct canvas size to the framework, so
/// `MediaQuery`, layout, and hit-testing all agree.
///
/// The earlier widget-tree wrapper here caused a layout/hit-test
/// mismatch (MaterialApp's internal MediaQuery used the full browser
/// viewport while the SizedBox constrained layout to 430×932 — buttons
/// rendered in one position but tap zones were elsewhere).

class MaterialAppWidget extends StatelessWidget {
  const MaterialAppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return UserSelector(
      selector: (state) => state.language,
      builder: (context, language) => ConfigSelector(
        selector: (config) => config.translations,
        builder: (context, translations) => ConfigSelector(
          selector: (config) => config.styling,
          builder:(context, state) => BlocBuilder<UserBloc, UserState>(builder: (context, state) {
            return MaterialApp(
              key: mainKey,
              navigatorKey: navigatorKey,
              navigatorObservers: [NavObs()],
              debugShowCheckedModeBanner: false,
              color: context.colors.primary,
              theme: MainTheme.lightTheme,
              darkTheme: MainTheme.lightTheme,
              themeMode: ThemeMode.light,
              locale: Locale(printR('CURRENT_LOCALE_IS', language)),
              // supportedLocales: LocalizationsHelper.getSupportedLocales(),
              localizationsDelegates: LocalizationsHelper.getTranslationDelegates(language, translations),
              localeResolutionCallback: LocalizationsHelper.localeResolutionCallback,
              // localeListResolutionCallback: LocalizationsHelper.localeListResolutionCallback,
              builder: (context, child) {
                SizeConfig.initSize(context);
                return Directionality(
                  textDirection:state.language == 'en' ? TextDirection.ltr : TextDirection.rtl,
                  child: ScaffoldMessenger(
                    child: child!,
                  ),
                );
              },
              home: const SplashScreen(),
            );
          },),
        ),
      ),
    );
  }
}

class NavObs extends NavigatorObserver {
  final List<String> routes = [];

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    routes.add(route.settings.name ?? '_');
    // print('NAV OBS $routes');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    routes.removeWhere((e) => oldRoute?.settings.name == null ? false : oldRoute!.settings.name == e);
    routes.add(newRoute?.settings.name ?? '_');
    // print('NAV OBS $routes');
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    routes.removeWhere((e) => route.settings.name == null ? false : route.settings.name == e);
    // print('NAV OBS $routes');
  }
}
