import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pica_comic/views/eh_views/eh_search_page.dart';
import 'package:pica_comic/views/hitomi_views/hitomi_search.dart';
import 'package:pica_comic/views/jm_views/jm_search_page.dart';
import 'package:pica_comic/views/pic_views/search_page.dart';
import 'package:pica_comic/views/widgets/search.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import '../base.dart';
import 'package:pica_comic/network/jm_network/jm_main_network.dart';
import 'jm_views/jm_comic_page.dart';

class PreSearchController extends GetxController{
  int target = 0;
  int picComicsOrder = appdata.getSearchMode();
  int jmComicsOrder = int.parse(appdata.settings[19]);

  void updateTarget(int i){
    target = i;
    update();
  }

  void updatePicComicsOrder(int i){
    picComicsOrder = i;
    appdata.setSearchMode(i);
    update();
  }

  void updateJmComicsOrder(int i){
    jmComicsOrder = i;
    appdata.settings[19] = i.toString();
    appdata.updateSettings();
    update();
  }
}

class PreSearchPage extends StatelessWidget {
  PreSearchPage({Key? key}) : super(key: key);
  final controller = TextEditingController();
  final searchController = Get.put(PreSearchController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.search),
        onPressed: (){
          switch(searchController.target){
            case 0: Get.to(()=>SearchPage(controller.text));break;
            case 1: Get.to(()=>EhSearchPage(controller.text));break;
            case 2: Get.to(()=>JmSearchPage(controller.text));break;
            case 3: Get.to(()=>HitomiSearchPage(controller.text));break;
          }
        },
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              floating: true,
              pinned: true,
              delegate: _SliverAppBarDelegate(
                minHeight: 60,
                maxHeight: 0,
                child: FloatingSearchBar(supportingText: '搜索'.tr,f:(s){
                  if(s=="") return;
                  switch(searchController.target){
                    case 0: Get.to(()=>SearchPage(controller.text));break;
                    case 1: Get.to(()=>EhSearchPage(controller.text));break;
                    case 2: Get.to(()=>JmSearchPage(controller.text));break;
                    case 3: Get.to(()=>HitomiSearchPage(controller.text));break;
                  }
                },
                  controller: controller,
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(top: 5)),
            SliverToBoxAdapter(
              child: GetBuilder<PreSearchController>(builder: (logic){
                return Card(
                  elevation: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(13, 5, 0, 0),
                        child: Text("目标".tr),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                        child: Wrap(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(5),
                              child: FilterChip(
                                label: const Text("Picacg"),
                                selected: logic.target==0,
                                onSelected: (b){
                                  logic.updateTarget(0);
                                },
                              ),
                            ),
                            if(appdata.settings[21][1] == "1")
                            Padding(
                              padding: const EdgeInsets.all(5),
                              child: FilterChip(
                                label: const Text("E-Hentai"),
                                selected: logic.target==1,
                                onSelected: (b){
                                  logic.updateTarget(1);
                                },
                              ),
                            ),
                            if(appdata.settings[21][2] == "1")
                            Padding(
                              padding: const EdgeInsets.all(5),
                              child: FilterChip(
                                label: const Text("JmComic"),
                                selected: logic.target==2,
                                onSelected: (b){
                                  logic.updateTarget(2);
                                },
                              ),
                            ),
                            if(appdata.settings[21][3] == "1")
                            Padding(
                              padding: const EdgeInsets.all(5),
                              child: FilterChip(
                                label: const Text("Hitomi"),
                                selected: logic.target==3,
                                onSelected: (b){
                                  logic.updateTarget(3);
                                },
                              ),
                            ),
                            if(appdata.settings[21][2] == "1")
                            Padding(
                              padding: const EdgeInsets.all(5),
                              child: ActionChip(
                                label: Text("禁漫漫画ID".tr),
                                onPressed: (){
                                  var controller = TextEditingController();
                                  showDialog(context: context, builder: (context){
                                    return AlertDialog(
                                      title: Text("输入禁漫漫画ID".tr),
                                      content: Padding(
                                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                                        child: TextField(
                                          keyboardType: TextInputType.number,
                                          controller: controller,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(RegExp("[0-9]"))
                                          ],
                                          decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                              labelText: "ID",
                                              prefix: Text("JM")
                                          ),
                                        ),
                                      ),
                                      actions: [
                                        TextButton(onPressed: (){
                                          Get.back();
                                          if(controller.text.isNum){
                                            Get.to(()=>JmComicPage(controller.text));
                                          }else{
                                            showMessage(Get.context, "输入的ID不是数字".tr);
                                          }
                                        }, child: Text("提交".tr))
                                      ],
                                    );
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },),
            ),
            SliverToBoxAdapter(
              child: GetBuilder<PreSearchController>(
                builder: (logic){
                  if(logic.target == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Card(
                        elevation: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(13, 5, 0, 0),
                              child: Text("漫画排序模式".tr),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                              child: Wrap(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: FilterChip(
                                      label: Text("新到书".tr),
                                      selected: logic.picComicsOrder == 0,
                                      onSelected: (b) {
                                        logic.updatePicComicsOrder(0);
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: FilterChip(
                                      label: Text("旧到新".tr),
                                      selected: logic.picComicsOrder == 1,
                                      onSelected: (b) {
                                        logic.updatePicComicsOrder(1);
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: FilterChip(
                                      label: Text("最多喜欢".tr),
                                      selected: logic.picComicsOrder == 2,
                                      onSelected: (b) {
                                        logic.updatePicComicsOrder(2);
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: FilterChip(
                                      label: Text("最多指名".tr),
                                      selected: logic.picComicsOrder == 3,
                                      onSelected: (b) {
                                        logic.updatePicComicsOrder(3);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }else if(logic.target == 2){
                    return Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Card(
                        elevation: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(13, 5, 0, 0),
                              child: Text("漫画排序模式".tr),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                              child: Wrap(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: FilterChip(
                                      label: Text("最新".tr),
                                      selected: logic.jmComicsOrder == 0,
                                      onSelected: (b) {
                                        logic.updateJmComicsOrder(0);
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: FilterChip(
                                      label: Text("最多点击".tr),
                                      selected: logic.jmComicsOrder == 1,
                                      onSelected: (b) {
                                        logic.updateJmComicsOrder(1);
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: FilterChip(
                                      label: Text("最多图片".tr),
                                      selected: logic.jmComicsOrder == 5,
                                      onSelected: (b) {
                                        logic.updateJmComicsOrder(5);
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: FilterChip(
                                      label: Text("最多喜欢".tr),
                                      selected: logic.jmComicsOrder == 6,
                                      onSelected: (b) {
                                        logic.updateJmComicsOrder(6);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return const SizedBox();
                  }
                },
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(top: 5)),
            SliverToBoxAdapter(
              child: Card(
                margin: const EdgeInsets.all(10),
                elevation: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("  哔咔热搜".tr),
                    Wrap(
                      children: [
                        for(var s in hotSearch)
                          Card(
                            margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                            elevation: 0,
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            child: InkWell(
                              borderRadius: const BorderRadius.all(Radius.circular(16)),
                              onTap: ()=>Get.to(()=>SearchPage(s)),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(8, 5, 8, 5), child: Text(s),),
                            ),
                          )
                      ],
                    )
                  ],
                ),
              ),
            ),
            if(appdata.settings[21][2] == "1")
            SliverToBoxAdapter(
              child: Card(
                margin: const EdgeInsets.all(10),
                elevation: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("  禁漫热搜".tr),
                    Wrap(
                      children: [
                        for(var s in jmNetwork.hotTags)
                          Card(
                            margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                            elevation: 0,
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            child: InkWell(
                              borderRadius: const BorderRadius.all(Radius.circular(16)),
                              onTap: ()=>Get.to(()=>JmSearchPage(s)),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(8, 5, 8, 5), child: Text(s),),
                            ),
                          )
                      ],
                    )
                  ],
                ),
              ),
            ),
            GetBuilder<PreSearchController>(
              builder: (controller){
                return SliverToBoxAdapter(
                  child: Card(
                    margin: const EdgeInsets.all(10),
                    elevation: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("  历史搜索".tr),
                        Wrap(
                          children: [
                            for(var s in appdata.searchHistory.reversed)
                              Card(
                                margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                                elevation: 0,
                                color: Theme.of(context).colorScheme.surfaceVariant,
                                child: InkWell(
                                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                                  onTap: (){
                                    switch(searchController.target){
                                      case 0: Get.to(()=>SearchPage(s));break;
                                      case 1: Get.to(()=>EhSearchPage(s));break;
                                      case 2: Get.to(()=>JmSearchPage(s));break;
                                      case 3: Get.to(()=>HitomiSearchPage(s));break;
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(8, 5, 8, 5), child: Text(s),),
                                ),
                              ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
            GetBuilder<PreSearchController>(
              builder: (controller){
                if(appdata.searchHistory.isNotEmpty) {
                  return SliverToBoxAdapter(
                  child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 13),
                          child: InkWell(
                            borderRadius: const BorderRadius.all(Radius.circular(10),),
                            onTap: (){
                              appdata.searchHistory.clear();
                              appdata.writeHistory();
                              controller.update();
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                                  color: Theme.of(context).colorScheme.secondaryContainer
                              ),
                              width: 125,
                              height: 26,
                              child: Row(
                                children: [
                                  const SizedBox(width: 5,),
                                  const Icon(Icons.clear_all,color: Colors.indigo,),
                                  Text("清除历史记录".tr)
                                ],
                              ),
                            ),
                          ),
                        )
                      ]
                  ),
                );
                }else{
                  return const SliverPadding(padding: EdgeInsets.all(0));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate{
  _SliverAppBarDelegate({required this.child,required this.maxHeight,required this.minHeight});
  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child,);
  }

  @override
  double get maxExtent => minHeight;

  @override
  double get minExtent => max(maxHeight,minHeight);

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxExtent || minHeight != oldDelegate.minExtent;
  }

}