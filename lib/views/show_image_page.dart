import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter/services.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/tools/save_image.dart';

class ShowImagePage extends StatefulWidget {
  const ShowImagePage(this.url,{this.eh=false,Key? key}) : super(key: key);
  final String url;
  final bool eh;

  @override
  State<ShowImagePage> createState() => _ShowImagePageState();
}

class _ShowImagePageState extends State<ShowImagePage> {
  late final String url = widget.url;
  _ShowImagePageState();

  @override
  initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    super.initState();
  }

  @override
  dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            color: Colors.black,
          ),
          child: Stack(
            children: [
              Positioned(child: PhotoView(
                minScale: PhotoViewComputedScale.contained*0.9,
                imageProvider: CachedNetworkImageProvider(widget.eh?url:getImageUrl(url)),
                loadingBuilder: (context,event){
                  return Container(
                    decoration: const BoxDecoration(color: Colors.black),
                    child: const Center(child: CircularProgressIndicator(),),
                  );
                },
              )),
              //顶部工具栏
              Positioned(
                top: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    //borderRadius: const BorderRadius.only(bottomRight: Radius.circular(10),bottomLeft: Radius.circular(10))
                  ),
                  width: MediaQuery.of(context).size.width+MediaQuery.of(context).padding.top,
                  child: Padding(
                    padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                    child: Row(
                      children: [
                        Padding(padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),child: Tooltip(
                          message: "返回".tr,
                          child: IconButton(
                            iconSize: 25,
                            icon: const Icon(Icons.arrow_back_outlined,color: Colors.white70),
                            onPressed: ()=>Get.back(),
                          ),
                        ),),
                        Container(
                          width: MediaQuery.of(context).size.width-150,
                          height: 50,
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width-75),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text("图片".tr,overflow: TextOverflow.ellipsis,style: const TextStyle(fontSize: 20,color: Colors.white70),),
                          )
                          ,),
                        Tooltip(
                          message: "保存图片".tr,
                          child: IconButton(
                            icon: const Icon(Icons.download,color: Colors.white70,),
                            onPressed: () async{
                              saveImage(getImageUrl(url),"");
                            },
                          ),
                        ),
                        Tooltip(
                          message: "分享".tr,
                          child: IconButton(
                            icon: const Icon(Icons.share,color: Colors.white70),
                            onPressed: () async{
                              shareImageFromCache(url,"");
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),),
            ],
          ),
        ),
    );
  }
}



