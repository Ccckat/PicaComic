import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/download_page.dart';
import 'package:pica_comic/views/widgets/downloading_tile.dart';
import 'package:pica_comic/views/widgets/pop_up_widget_scaffold.dart';

class DownloadingPageLogic extends GetxController{
  var items = <Widget>[];
}

class DownloadingPage extends StatefulWidget {
  const DownloadingPage({this.inPopupWidget=false, Key? key}) : super(key: key);
  final bool inPopupWidget;

  @override
  State<DownloadingPage> createState() => _DownloadingPageState();
}

class _DownloadingPageState extends State<DownloadingPage> {
  @override
  void dispose() {
    super.dispose();
    downloadManager.whenChange = (){};
    downloadManager.handleError = (){};
  }

  @override
  Widget build(BuildContext context) {
    final body = GetBuilder<DownloadingPageLogic>(
      init: DownloadingPageLogic(),
      builder: (logic){
        for(var i in downloadManager.downloading){
          logic.items.add(DownloadingTile(i, () {
            downloadManager.cancel(i.id);
            logic.update();
          }));
        }
        downloadManager.whenChange = (){
          logic.items.clear();
          for(var i in downloadManager.downloading){
            logic.items.add(DownloadingTile(i, () {
              downloadManager.cancel(i.id);
              logic.update();
            }));
          }
          logic.update();
          try {
            Get.find<DownloadPageLogic>().fresh();
          }
          catch(e){
            //如果用户从通知中进入此页面, 可能在路由中不存在DownloadPage, 直接忽略
          }
        };
        downloadManager.handleError = (){
          logic.update();
        };
        return ListView.builder(
            itemCount: downloadManager.downloading.length+1,
            itemBuilder: (context,index){
              if(index == 0){
                return MaterialBanner(
                    leading: downloadManager.isDownloading?
                      const Icon(Icons.downloading,color: Colors.blue,):
                      const Icon(Icons.pause_circle_outline_outlined,color: Colors.red,),
                    content: downloadManager.error?
                      Text("下载出错".tr):
                      Text("${"@length 项下载任务".trParams({"length":downloadManager.downloading.length.toString()})}${downloadManager.isDownloading?" 下载中".tr:(downloadManager.downloading.isNotEmpty?" 已暂停".tr:"")}"),
                    actions: [
                      if(downloadManager.downloading.isNotEmpty)
                        TextButton(
                          onPressed: (){
                            downloadManager.isDownloading?downloadManager.pause():downloadManager.start();
                            logic.update();
                          },
                          child: downloadManager.isDownloading?
                            Text("暂停".tr):
                            (downloadManager.error?Text("重试".tr):Text("继续".tr)),
                        )
                      else
                        const Text(""),
                    ]
                );
              }else {
                return logic.items[index-1];
              }
            }
        );
      },
    );
    if(widget.inPopupWidget){
      return PopUpWidgetScaffold(
        title: "下载管理器".tr,
        body: body,
      );
    }else{
      return Scaffold(
        appBar: AppBar(title: Text("下载管理器".tr),),
        body: body,
      );
    }
  }
}