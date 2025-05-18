import 'dart:async';

import 'package:dots_indicator/dots_indicator.dart';
import 'package:escola/core/config/config.dart';
import 'package:escola/core/config/widgets/config_builder.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/features/home/widgets/home_card_item.dart';
import 'package:flutter/material.dart';

class HomeCardsList extends StatefulWidget {
  const HomeCardsList({super.key});

  @override
  State<HomeCardsList> createState() => _HomeCardsListState();
}

class _HomeCardsListState extends State<HomeCardsList> {
  late final PageController pageController;
  late final Timer timer;
  int pageIndex = 0;

  @override
  void initState() {
    pageController = PageController(viewportFraction: 1);
    timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (pageController.hasClients) {
        int page = pageController.page?.round() ?? 0;
        if (page == Config.get.homeCards.length - 1) {
          page = 0;
          pageIndex = 0;
        } else {
          page++;
          pageIndex++;
        }
        pageController.animateToPage(page, duration: const Duration(milliseconds: 1000), curve: Curves.easeInOut);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ConfigSelector(
      selector: (config) => config.homeCards,
      builder: (context, cards) {
        if (cards.isEmpty) return const SizedBox();
        return Container(
          height: 275.csh,
          color: context.colors.primaryDark,
          width: double.maxFinite,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 181.csh,
                  child: PageView.builder(
                    controller: pageController,
                    onPageChanged: (pageIndex) => setState(
                      () {
                        this.pageIndex = pageIndex;
                      },
                    ),
                    itemCount: cards.length,
                    padEnds: true,
                    itemBuilder: (context, index) {
                      return HomeCardItem(cardModel: cards[index]);
                    },
                  ),
                ),
                SizedBox(height: 31.csh),
                DotsIndicator(
                  dotsCount: cards.length,
                  position: (pageIndex >= cards.length ? cards.length - 1 : pageIndex).toDouble(),
                  decorator: DotsDecorator(
                    size: Size(8.csw, 8.csh),
                    activeSize: Size(8.csw, 8.csh),
                    color: context.colors.scaffold.withOpacity(0.5),
                    activeColor: context.colors.scaffold,
                    spacing: EdgeInsets.symmetric(horizontal: 5.csw),
                  ),
                ),
                SizedBox(
                  height: 15.csh,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
