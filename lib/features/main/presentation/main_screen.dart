import 'package:escola/core/components/true_automatic_keep_alive.dart';
import 'package:escola/core/config/config.dart';
import 'package:escola/core/config/widgets/config_builder.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/background_services/bloc/background_services_bloc.dart';
import 'package:escola/features/diary/presentation/dairy_screen.dart';
import 'package:escola/features/featured_events/bloc/featured_events_bloc.dart';
import 'package:escola/features/featured_events/bloc/featured_events_state.dart';
import 'package:escola/features/featured_events/featured_events_screen.dart';
import 'package:escola/features/home/home_screen.dart';
import 'package:escola/features/main/bloc/main_bloc.dart';
import 'package:escola/features/main/presentation/widgets/custom_bottom_navigation.dart';
import 'package:escola/features/settings/events/event_screen.dart';
import 'package:escola/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late String _bottomNavId;
  late PageController _pageController;

  bool featuredDialogOpened = false;

  @override
  void initState() {
    context.read<BackgroundServicesBloc>().add(CallServices());
    _bottomNavId = context.read<MainBloc>().currentId;
    _pageController = PageController();

    BlocProvider.of<FeaturedEventsBloc>(context).fetch();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FeaturedEventsBloc, FeaturedEventsState>(
      listenWhen: compareStates([(s) => s.eventsState.data]),
      listener: (context, state) {
        if (validList(state.eventsState.data)) {
          if (!featuredDialogOpened) {
            featuredDialogOpened = true;
            FeaturedEventsScreen.open(context);
          }
        } else {
          if (featuredDialogOpened) {
            featuredDialogOpened = false;
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
          color: Colors.white,
          child: SafeArea(
            top: false,
            child: ConfigSelector<List<BottomBarItemModel>>(
              selector: (config) => config.bottomBar,
              builder: (context, items) => Scaffold(
                backgroundColor: Colors.white,
                body: BlocConsumer<MainBloc, MainState>(
                  listener: handleListener,
                  builder: (context, state) {
                    return PageView(
                      physics: const NeverScrollableScrollPhysics(),
                      controller: _pageController,
                      children: [
                        if (validList(items)) ...items.map((e) => getWidgetFromBottomBar(e.id)) else const HomeScreen(),
                      ].map((e) => TrueAutomaticKeepAlive(child: e)).toList(),
                    );
                  },
                ),
                bottomNavigationBar: !validList(items)
                    ? null
                    : BlocBuilder<MainBloc, MainState>(
                        builder: (context, state) {
                          return CustomBottomNavigation(
                            selectedId: _bottomNavId,
                            onTap: (id) => goToPageByIndex(id),
                          );
                        },
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void goToPageByIndex(String id) {
    context.read<MainBloc>().add(ChangePage(id: id));
  }

  handleListener(context, state) {
    if (state is ChangePageSucceed) {
      _bottomNavId = state.selectedPage;
      jumpToPage(state.selectedPage);
    }
  }

  void jumpToPage(String id) {
    final index = Config.get.bottomBar.indexWhere((e) => e.id == id);
    _pageController.jumpToPage(index);
  }

  Widget getWidgetFromBottomBar(String id) {
    const pages = PageID.values;
    bool find(PageID e) => e.name == id;
    if (pages.any(find)) {
      final page = pages.firstWhere(find);
      switch (page) {
        case PageID.home:
          return const HomeScreen();
        case PageID.diary:
          return const DiaryScreen();
        case PageID.events:
          return const EventsScreen();
        case PageID.settings:
          return const SettingsScreen();
      }
    }
    return const Placeholder();
  }
}
