import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/network/eh_network/eh_main_network.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/foundation/ui_mode.dart';
import 'package:pica_comic/views/eh_views/eh_search_page.dart';
import 'package:pica_comic/views/eh_views/eh_widgets/stars.dart';
import 'package:pica_comic/views/models/history.dart';
import 'package:pica_comic/views/widgets/show_error.dart';
import 'package:share_plus/share_plus.dart';
import '../../network/eh_network/get_gallery_id.dart';
import '../reader/goto_reader.dart';
import '../show_image_page.dart';
import '../widgets/loading.dart';
import '../widgets/selectable_text.dart';
import 'package:pica_comic/views/widgets/show_message.dart';

class GalleryPageLogic extends GetxController{
  bool loading = true;
  Gallery? gallery;
  var controller = ScrollController();
  bool showAppbarTitle = false;
  bool noNetwork = false;
  String cookies = "";
  String? message;

  void loadInfo(EhGalleryBrief brief) async{
    var res = await EhNetwork().getGalleryInfo(brief);
    if(res.error){
      message = res.errorMessage;
    }else {
      gallery = res.data;
    }
    cookies = await EhNetwork().getCookies();
    loading = false;
    update();
  }
  void retry(){
    loading = true;
    update();
  }
  void updateStars(double value){
    gallery!.stars = value/2;
    update;
  }
}

class EhGalleryPage extends StatelessWidget {
  const EhGalleryPage(this.brief,{this.downloaded = false,Key? key}) : super(key: key);
  final EhGalleryBrief brief;
  final bool downloaded;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: GetBuilder<GalleryPageLogic>(
        init: GalleryPageLogic(),
        initState: (logic){
          //添加历史记录
          Future.delayed(const Duration(milliseconds: 300),(){
            try{
              var history = NewHistory(
                  HistoryType.ehentai,
                  DateTime.now(),
                  brief.title,
                  brief.uploader,
                  brief.coverPath,
                  0,
                  0,
                  brief.link
              );
              appdata.history.addHistory(history);
            }
            catch(e){
              //Get会在初始化logic前调用此函数, 延迟300ms可能仍然没有初始化完成
            }
          });
        },
        builder: (logic){
          if(downloaded){
            logic.loading = false;
          }
          if(logic.loading){
            logic.loadInfo(brief);
            return showLoading(context);
          }else if(logic.gallery == null){
            return showNetworkError(logic.message??"网络错误", logic.retry, context);
          }else{
            logic.controller = ScrollController();
            logic.controller.addListener(() {
              //检测当前滚动位置, 决定是否显示Appbar的标题
              bool temp = logic.showAppbarTitle;
              if(!logic.controller.hasClients){
                return;
              }
              logic.showAppbarTitle = logic.controller.position.pixels>
                  boundingTextSize(
                      logic.gallery!.title,
                      const TextStyle(fontSize: 22),
                      maxWidth: width
                  ).height+50;
              if(temp!=logic.showAppbarTitle) {
                logic.update();
              }
            });
            return CustomScrollView(
              controller: logic.controller,
              slivers: [
                SliverAppBar(
                  surfaceTintColor: logic.showAppbarTitle?null:Colors.transparent,
                  shadowColor: Colors.transparent,
                  title: AnimatedOpacity(
                    opacity: logic.showAppbarTitle?1.0:0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(logic.gallery!.title),
                  ),
                  pinned: true,
                  actions: [
                    Tooltip(
                      message: "分享".tr,
                      child: IconButton(
                        icon: const Icon(Icons.share,),
                        onPressed: () {
                          Share.share(logic.gallery!.title);
                        },
                      ),)
                  ],
                ),

                //标题
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 20, 10, 15),
                    child: SizedBox(
                      width: double.infinity,
                      child: SelectableTextCN(
                        text: logic.gallery!.title,
                        style: const TextStyle(fontSize: 28),
                        withAddToBlockKeywordButton: true,
                      ),
                    ),
                  ),
                ),

                buildGalleryInfo(context,logic),

                if(! logic.noNetwork)
                const SliverToBoxAdapter(
                  child: Divider(),
                ),

                if(! logic.noNetwork)
                buildComments(logic, context),

                SliverPadding(padding: MediaQuery.of(context).padding),
              ],
            );
          }
        },
      ),
    );
  }

  Widget buildGalleryInfo(BuildContext context, GalleryPageLogic logic){
    var s = logic.gallery!.stars ~/ 0.5;
    if(UiMode.m1(context)){
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: SizedBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [

                //封面
                buildCover(context, 350, MediaQuery.of(context).size.width, logic),

                if(! logic.noNetwork)
                const SizedBox(height: 20,),
                if(! logic.noNetwork)
                ...buildInfoCards(logic, context),
                SizedBox(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("评分".tr),
                        SizedBox(
                          height: 30,
                          child: Row(
                            children: [
                              const SizedBox(width: 2,),
                              for(int i=0;i<s~/2;i++)
                                Icon(Icons.star,size: 30,color: Theme.of(context).colorScheme.secondary,),
                              if(s%2==1)
                                Icon(Icons.star_half,size: 30,color: Theme.of(context).colorScheme.secondary,),
                              for(int i=0;i<(5 - s~/2 - s%2);i++)
                                const Icon(Icons.star_border,size: 30,),
                              const SizedBox(width: 5,),
                              if(logic.gallery!.rating!=null)
                                Text(logic.gallery!.rating!)
                            ],
                          ),
                        ),
                      ]
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }else{
      return SliverToBoxAdapter(child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Row(
          children: [
            //封面
            SizedBox(
              child: Column(
                children: [
                  buildCover(context, 550, MediaQuery.of(context).size.width/2,logic),
                ],
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width/2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if(! logic.noNetwork)
                    Text("评分".tr),
                  if(! logic.noNetwork)
                  SizedBox(
                    height: 30,
                    child: Row(
                      children: [
                        for(int i=0;i<s~/2;i++)
                          Icon(Icons.star,size: 30,color: Theme.of(context).colorScheme.secondary,),
                        if(s%2==1)
                          Icon(Icons.star_half,size: 30,color: Theme.of(context).colorScheme.secondary,),
                        for(int i=0;i<(5 - s~/2 - s%2);i++)
                          const Icon(Icons.star_border,size: 30,),
                        const SizedBox(width: 5,),
                        if(logic.gallery!.rating!=null)
                          Text(logic.gallery!.rating!)
                      ],
                    ),
                  ),
                  ...buildInfoCards(logic, context),
                ]
              ),
            ),
          ],
        ),
      ),);
    }
  }

  Widget buildCover(BuildContext context, double height, double width, GalleryPageLogic logic){
    return GestureDetector(
      onTap: logic.noNetwork?null:()=>Get.to(()=>ShowImagePage(logic.gallery!.coverPath,eh: true,)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
        child: logic.noNetwork?Image.file(
          downloadManager.getCover(getGalleryId(brief.link)),
          width: width-50,
          height: height,
          fit: BoxFit.contain,
        ):CachedNetworkImage(
          useOldImageOnUrlChange: true,
          width: width-50,
          height: height,
          imageUrl: logic.gallery!.coverPath,
          fit: BoxFit.contain,
          httpHeaders: {
            "Cookie": logic.cookies
          },
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      ),
    );
  }

  List<Widget> buildInfoCards(GalleryPageLogic logic, BuildContext context){
    var res = <Widget>[];
    var res2 = <Widget>[];

    res.add(const Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Text("type"),
    ));
    res.add(buildInfoCard(logic.gallery!.type, context));
    res.add(const Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Text("time"),
    ));
    res.add(buildInfoCard(logic.gallery!.time, context,allowSearch: false));
    for(var key in logic.gallery!.tags.keys){
      res.add(Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        child: Text(key),
      ));
      res.add(Wrap(
        children: [
          for(var s in logic.gallery!.tags[key]!)
            buildInfoCard(s, context),
        ],
      ));
    }
    res2.add(Padding(
      padding: const EdgeInsets.fromLTRB(10, 15, 20, 0),
      child: Row(
        children: [
          Expanded(child: ActionChip(
            label: Text("评分".tr),
            avatar: const Icon(Icons.star),
            onPressed: (){
              if(logic.noNetwork){
                showMessage(context, "无网络");
              }else{
                starRating(context, logic.gallery!.auth!);
              }
            },
          ),),
          SizedBox.fromSize(size: const Size(10,1),),
          Expanded(child: ActionChip(
            label: Text("收藏".tr),
            avatar: logic.gallery!.favorite?const Icon(Icons.bookmark):const Icon(Icons.bookmark_outline),
            onPressed: (){
              if(!logic.gallery!.favorite){
                showDialog(context: context, builder: (context)=>FavoriteComicDialog(logic));
              }else{
                showMessage(context, "正在取消收藏".tr);
                EhNetwork().unfavorite(logic.gallery!.auth!["gid"]!, logic.gallery!.auth!["token"]!).then((b){
                  if(b){
                    showMessage(Get.context, "取消收藏成功".tr);
                    logic.gallery!.favorite = false;
                    logic.update();
                  }else{
                    showMessage(Get.context, "取消收藏失败".tr);
                  }
                });
              }
            }
          ),),
          SizedBox.fromSize(size: const Size(10,1),),
          Expanded(child: ActionChip(
            label: const Text("评论"),
            avatar: const Icon(Icons.comment_outlined),
            onPressed: (){
              comment(context, logic.gallery!.link);
            }
          ),),
        ],
      ),
    ));
    res2.add(Padding(
      padding: const EdgeInsets.fromLTRB(10, 15, 20, 10),
      child: Row(
        children: [
          Expanded(child: FilledButton(
            onPressed: (){
              final id = getGalleryId(logic.gallery!.link);
              if(downloadManager.downloadedGalleries.contains(id)){
                showMessage(context, "已下载".tr);
                return;
              }
              for(var i in downloadManager.downloading){
                if(i.id == id){
                  showMessage(context, "下载中".tr);
                  return;
                }
              }
              downloadManager.addEhDownload(logic.gallery!);
              showMessage(context, "已加入下载队列".tr);
            },
            child: (downloadManager.downloadedGalleries.contains(getGalleryId(logic.gallery!.link)))?const Text("已下载"):const Text("下载"),
          ),),
          SizedBox.fromSize(size: const Size(10,1),),
          Expanded(child: FilledButton(
            onPressed: () => readEhGallery(logic.gallery!),
            child: Text("阅读".tr),
          ),),

        ],
      ),
    ));
    return !UiMode.m1(context)?res+res2:res2+res;
  }

  Widget buildInfoCard(String title, BuildContext context, {bool allowSearch=true}){
    return GestureDetector(
      onLongPressStart: (details){
        showMenu(
            context: context,
            position: RelativeRect.fromLTRB(details.globalPosition.dx, details.globalPosition.dy, details.globalPosition.dx, details.globalPosition.dy),
            items: [
              PopupMenuItem(
                child: Text("复制".tr),
                onTap: (){
                  Clipboard.setData(ClipboardData(text: (title)));
                  showMessage(context, "已复制".tr);
                },
              ),
            ]
        );
      },
      child: Card(
        margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
        elevation: 0,
        color: Theme
            .of(context)
            .colorScheme
            .primaryContainer,
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          onTap: allowSearch?()=>Get.to(()=>EhSearchPage(title),preventDuplicates: false):(){},
          onSecondaryTapUp: (details){
            showMenu(
                context: context,
                position: RelativeRect.fromLTRB(details.globalPosition.dx, details.globalPosition.dy, details.globalPosition.dx, details.globalPosition.dy),
                items: [
                  PopupMenuItem(
                    child: Text("复制".tr),
                    onTap: (){
                      Clipboard.setData(ClipboardData(text: (title)));
                      showMessage(context, "已复制".tr);
                    },
                  ),
                ]
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 5, 8, 5), child: Text(title),
          ),
        ),
      ),
    );
  }

  Size boundingTextSize(String text, TextStyle style,  {int maxLines = 2^31, double maxWidth = double.infinity}) {
    if (text.isEmpty) {
      return Size.zero;
    }
    final TextPainter textPainter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(text: text, style: style), maxLines: maxLines)
      ..layout(maxWidth: maxWidth);
    return textPainter.size;
  }

  Widget buildComments(GalleryPageLogic logic, BuildContext context){
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        child: SizedBox(
          child: Column(
            children: [
              const SizedBox(
                width: 800,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(10, 0, 0, 5),
                  child: Text("评论",style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),),
                ),
              ),
              for(var comment in logic.gallery!.comments)
                SizedBox(
                  width: 800,
                  child: Card(
                    margin: const EdgeInsets.all(5),
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${logic.gallery!.uploader==comment.name?"(上传者)":""}${comment.name}",style: const TextStyle(fontSize: 16,fontWeight: FontWeight.w500),),
                          const SizedBox(height: 2,),
                          SelectableTextCN(text: comment.content)
                        ],
                      ),
                    ),
                  ),
                )
            ],
          ),
        ),
      )
    );
  }

  void starRating(BuildContext context, Map<String, String> auth){
    if(appdata.ehId==""){
      showMessage(context, "未登录".tr);
      return;
    }
    showDialog(context: context, builder: (dialogContext)=>GetBuilder<RatingLogic>(
      init: RatingLogic(),
      builder: (logic)=>SimpleDialog(
        title: const Text("评分"),
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 100,
            child: Center(
              child: SizedBox(
                width: 210,
                child: Column(
                  children: [
                    const SizedBox(height: 10,),
                    RatingWidget(
                      padding: 2,
                      onRatingUpdate: (value)=>logic.rating = value,
                      value: 0,
                      selectAble: true,
                      size: 40,
                    ),
                    const Spacer(),
                    if(!logic.running)
                      FilledButton(onPressed: (){
                        logic.running = true;
                        logic.update();
                        EhNetwork().rateGallery(auth,logic.rating.toInt()).then((b){
                          if(b){
                            Get.back();
                            showMessage(context, "评分成功".tr);
                            Get.find<GalleryPageLogic>().updateStars(logic.rating);
                          }else{
                            logic.running = false;
                            logic.update();
                            showMessage(dialogContext, "网络错误");
                          }
                        });
                      }, child: Text("提交".tr))
                    else
                      const CircularProgressIndicator()
                  ],
                ),
              ),
            ),
          )
        ],
      )
    ));
  }

  void comment(BuildContext context, String link){
    if(appdata.ehId==""){
      showMessage(context, "未登录".tr);
      return;
    }
    showDialog(context: context, builder: (dialogContext)=>GetBuilder<CommentLogic>(
      init: CommentLogic(),
        builder: (logic)=>SimpleDialog(
          title: Text("发布评论".tr),
          children: [
            SizedBox(
              width: 400,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(5, 10, 5, 5),
                    child: TextField(
                      maxLines: 5,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder()
                      ),
                      controller: logic.controller,
                    ),
                  ),
                  if(!logic.sending)
                    FilledButton(onPressed: (){
                      logic.sending = true;
                      logic.update();
                      EhNetwork().comment(logic.controller.text,link).then((b){
                        if(!b.error){
                          Get.back();
                          showMessage(context, "评论成功".tr);
                          var pageLogic = Get.find<GalleryPageLogic>();
                          pageLogic.gallery!.comments.add(Comment(appdata.ehAccount, logic.controller.text, "now"));
                          pageLogic.update();
                        }else{
                          logic.sending = false;
                          logic.update();
                          showMessage(context, b.errorMessage??"网络错误.tr");
                        }
                      });
                    }, child: Text("提交".tr))
                  else
                    const CircularProgressIndicator()
                ],
              ),
            )
          ],
    )));
  }

  void loadGalleryInfoFromFile(GalleryPageLogic logic) async{
    logic.gallery = (await downloadManager.getGalleryFormId(getGalleryId(brief.link))).gallery;
    //避免加载完成后页面还没有渲染完成
    await Future.delayed(const Duration(milliseconds: 100));
    logic.noNetwork = true;
    logic.update();
  }


}

class RatingLogic extends GetxController{
  double rating = 0;
  bool running = false;
}

class CommentLogic extends GetxController{
  final controller = TextEditingController();
  bool sending = false;
}

class FavoriteComicDialog extends StatefulWidget {
  const FavoriteComicDialog(this.logic, {Key? key}) : super(key: key);
  final GalleryPageLogic logic;

  @override
  State<FavoriteComicDialog> createState() => _FavoriteComicDialogState();
}

class _FavoriteComicDialogState extends State<FavoriteComicDialog> {
  bool loading = false;
  Map<String, String> folders = Map<String, String>.fromIterables(
      EhNetwork().folderNames, List<String>.generate(10, (index) => index.toString()));
  String? message;
  String folderId = "0";
  late String folderName = folders.keys.first;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text("收藏漫画".tr),
      children: [
        SizedBox(
          key: const Key("2"),
          width: 300,
          height: 150,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(5),
                width: 300,
                height: 50,
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: const BorderRadius.all(Radius.circular(16))
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text("  选择收藏夹:  ".tr),
                    Text(folderName),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.arrow_drop_down_sharp),
                      onPressed: (){
                        showMenu(
                            context: context,
                            position: RelativeRect.fromLTRB(
                                MediaQuery.of(context).size.width/2+150,
                                MediaQuery.of(context).size.height/2,
                                MediaQuery.of(context).size.width/2-150,
                                MediaQuery.of(context).size.height/2),
                            items: [
                              for(var folder in folders.entries)
                                PopupMenuItem(
                                  child: Text(folder.key),
                                  onTap: (){
                                    setState(() {
                                      folderName = folder.key;
                                    });
                                    folderId = folder.value;
                                  },
                                )
                            ]
                        );
                      },
                    )
                  ],
                ),
              ),
              const SizedBox(height: 20,),
              if(!loading)
                FilledButton(onPressed: () async{
                  setState(() {
                    loading = true;
                  });
                  var res = await EhNetwork().favorite(widget.logic.gallery!.auth!["gid"]!,widget.logic.gallery!.auth!["token"]!, id: folderId);
                  if (!res) {
                    showMessage(Get.context, "网络错误");
                    setState(() {
                      loading = false;
                    });
                    return;
                  }
                  Get.back();
                  widget.logic.gallery!.favorite = true;
                  widget.logic.update();
                  showMessage(Get.context, "添加成功".tr);
                }, child: Text("提交".tr))
              else
                const Center(
                  child: CircularProgressIndicator(),
                )
            ],
          ),
        )
      ],
    );
  }
}