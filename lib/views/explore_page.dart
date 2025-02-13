import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_main_network.dart';
import 'package:pica_comic/views/eh_views/eh_home_page.dart';
import 'package:pica_comic/views/eh_views/eh_popular_page.dart';
import 'package:pica_comic/views/hitomi_views/hitomi_home_page.dart';
import 'package:pica_comic/views/jm_views/jm_home_page.dart';
import 'package:pica_comic/views/jm_views/jm_latest_page.dart';
import 'package:pica_comic/views/pic_views/games_page.dart';
import 'package:pica_comic/views/pic_views/home_page.dart';
import 'models/tab_listener.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage(this.tabListener, this.pages, {Key? key}) : super(key: key);
  final TabListener tabListener;
  final int pages;

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> with TickerProviderStateMixin{
  late TabController controller;
  
  @override
  Widget build(BuildContext context) {
    widget.tabListener.controller = null;
    controller = TabController(length: widget.pages, vsync: this);
    widget.tabListener.controller = controller;
    return Column(
      children: [
        TabBar(
          splashBorderRadius: const BorderRadius.all(Radius.circular(10)),
          isScrollable: true,
          tabs: [
            if(appdata.settings[24][0] == "1")
              Tab(text: "Picacg".tr, key: const Key("Picacg"),),
            if(appdata.settings[24][1] == "1")
              Tab(text: "Picacg游戏".tr, key: const Key("Picacg游戏"),),
            if(appdata.settings[24][2] == "1")
              Tab(text: "Eh主页".tr, key: const Key("Eh主页"),),
            if(appdata.settings[24][3] == "1")
              Tab(text: "Eh热门".tr, key: const Key("Eh热门"),),
            if(appdata.settings[24][4] == "1")
              Tab(text: "禁漫主页".tr, key: const Key("禁漫主页")),
            if(appdata.settings[24][5] == "1")
              Tab(text: "禁漫最新".tr, key: const Key("禁漫最新")),
            if(appdata.settings[24][6] == "1")
              Tab(text: "Hitomi主页".tr, key: const Key("Hitomi主页")),
            if(appdata.settings[24][7] == "1")
              Tab(text: "Hitomi中文".tr, key: const Key("Hitomi中文")),
            if(appdata.settings[24][8] == "1")
              Tab(text: "Hitomi日文".tr, key: const Key("Hitomi日文")),
          ],
          controller: controller,
        ),
        Expanded(
          child: TabBarView(
            controller: controller,
            children: [
              if(appdata.settings[24][0] == "1")
                const HomePage(),
              if(appdata.settings[24][1] == "1")
                const GamesPage(),
              if(appdata.settings[24][2] == "1")
                const EhHomePage(),
              if(appdata.settings[24][3] == "1")
                const EhPopularPage(),
              if(appdata.settings[24][4] == "1")
                const JmHomePage(),
              if(appdata.settings[24][5] == "1")
                const JmLatestPage(),
              if(appdata.settings[24][6] == "1")
                HitomiHomePage(HitomiDataUrls.homePageAll),
              if(appdata.settings[24][7] == "1")
                HitomiHomePage(HitomiDataUrls.homePageCn),
              if(appdata.settings[24][8] == "1")
                HitomiHomePage(HitomiDataUrls.homePageJp),
            ],
          ),
        )
      ],
    );
  }
}

class ExplorePageLogic extends GetxController{}

class ExplorePageWithGetControl extends StatelessWidget {
  const ExplorePageWithGetControl(this.listener, {Key? key}) : super(key: key);
  final TabListener listener;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ExplorePageLogic>(builder: (logic){
      int pages = 0;
      for(int i=0;i<appdata.settings[24].length;i++){
        if(appdata.settings[24][i] == "1"){
          pages++;
        }
      }
      return ExplorePage(listener, pages, key: Key(pages.toString()),);
    });
  }
}
