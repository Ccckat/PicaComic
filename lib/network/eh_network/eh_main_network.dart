import 'dart:io';
import 'package:dio/dio.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/network/log_dio.dart';
import 'package:pica_comic/tools/js.dart';
import 'package:pica_comic/foundation/log.dart';
import '../../base.dart';
import '../proxy.dart';
import 'package:html/parser.dart';
import 'package:get/get.dart';
import '../../views/pre_search_page.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:pica_comic/network/cache_network.dart';
import 'package:pica_comic/network/res.dart';

class EhNetwork{
  factory EhNetwork() => cache==null?(cache=EhNetwork.create()):cache!;

  static EhNetwork? cache;

  static EhNetwork createEhNetwork() => EhNetwork();

  var folderNames = List.generate(10, (index) => "Favorite $index");

  EhNetwork.create(){
    updateUrl();
    getCookies();
  }

  ///e-hentai的url
  var _ehBaseUrl = "https://e-hentai.org";

  ///e-hentai的url
  get ehBaseUrl => _ehBaseUrl;

  ///api url
  var _ehApiUrl = "https://api.e-hentai.org/api.php";

  ///api url
  get ehApiUrl => _ehApiUrl;

  final cookieJar = CookieJar(ignoreExpires: true);

  ///给图片加载使用的cookie
  String cookiesStr = "";

  ///更新画廊站点
  void updateUrl(){
    _ehBaseUrl = appdata.settings[20]=="0"?"https://e-hentai.org":"https://exhentai.org";
    _ehApiUrl = appdata.settings[20]=="0"?"https://api.e-hentai.org/api.php":"https://exhentai.org/api.php";
    getCookies();
  }

  ///设置请求cookie
  Future<String> getCookies() async{
    if(appdata.ehAccount == ""){
      return "";
    }
    await cookieJar.saveFromResponse(Uri.parse(ehBaseUrl), [
      Cookie("nw", "1"),
      Cookie("ipb_member_id", appdata.ehId),
      Cookie("ipb_pass_hash", appdata.ehPassHash),
      if(appdata.igneous != "")
        Cookie("igneous", appdata.igneous),
    ]);
    var cookies = await cookieJar.loadForRequest(Uri.parse(ehBaseUrl));
    var res = "";
    for(var cookie in cookies){
      res += "${cookie.name}=${cookie.value}; ";
    }
    cookiesStr = res.substring(0,res.length-2);
    return cookiesStr;
  }

  ///从url获取数据, 在请求时设置了cookie
  Future<Res<String>> request(String url,
      {Map<String,String>? headers, CacheExpiredTime expiredTime=CacheExpiredTime.short}) async{
    if(appdata.ehId != "") {
      await cookieJar.saveFromResponse(Uri.parse(url), [
        Cookie("nw", "1"),
        Cookie("ipb_member_id", appdata.ehId.removeAllWhitespace),
        Cookie("ipb_pass_hash", appdata.ehPassHash),
        if(appdata.igneous != "")
          Cookie("igneous", appdata.igneous),
    ]);
    }
    var options = BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        followRedirects: true,
        headers: {
          "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36",
          ...?headers
        }
    );
    var dio = CachedNetwork();
    try {
      var data = await dio.get(
          url,
          options,
          cookieJar: cookieJar,
          expiredTime: expiredTime
        );
      await getCookies();//确保cookie处于最新状态
      if((data.data).substring(0,4) == "Your"){
        return Res(null, errorMessage: "Your IP address has been temporarily banned");
      }
      return Res(data.data);
    }
    on DioException catch(e){
      String? message;
      sendNetworkLog(url, e.toString());
      if(e.type!=DioExceptionType.unknown){
        message = e.message??"未知".tr;
      }else{
        message = e.toString().split("\n").elementAtOrNull(1);
      }
      return Res(null, errorMessage: message??"网络错误");
    }
    catch(e){
      String? message;
      if(e.toString() != "null"){
        message = e.toString();
      }
      return Res(null, errorMessage: message??"网络错误");
    }
  }

  ///eh APi请求
  Future<Res<String>> apiRequest(Map<String, dynamic> data, {Map<String,String>? headers,}) async{
    await setNetworkProxy();//更新代理
    var options = BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        headers: {
          "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36",
          "cookie": "nw=1${appdata.ehId=="" ? "" : ";ipb_member_id=${appdata.ehId};ipb_pass_hash=${appdata.ehPassHash}"}",
          ...?headers
        }
    );

    var dio =  Dio(options)
      ..interceptors.add(LogInterceptor());

    try{
      var res = await dio.post<String>(ehApiUrl, data: data);
      return Res(res.data);
    }
    on DioException catch(e){
      String? message;
      if(e.type!=DioExceptionType.unknown){
        message = e.message??"未知".tr;
      }else{
        message = e.toString().split("\n").elementAtOrNull(1);
      }
      return Res(null, errorMessage: message??"网络错误");
    }
    catch(e){
      String? message;
      if(e.toString() != "null"){
        message = e.toString();
      }
      return Res(null, errorMessage: message??"网络错误");
    }
  }

  Future<Res<String>> post(String url, dynamic data, {Map<String,String>? headers,}) async{
    await cookieJar.saveFromResponse(Uri.parse(url), [
      Cookie("nw", "1"),
      Cookie("ipb_member_id", appdata.ehId),
      Cookie("ipb_pass_hash", appdata.ehPassHash),
      if(appdata.igneous != "")
        Cookie("igneous", appdata.igneous),
    ]);
    await setNetworkProxy();//更新代理
    var options = BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        receiveDataWhenStatusError: true,
        validateStatus: (status)=>status==200||status==302,
        headers: {
          "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36",
          ...?headers
        }
    );

    var dio =  logDio(options)
      ..interceptors.add(LogInterceptor());
    dio.interceptors.add(CookieManager(cookieJar));
    try{
      var res = await dio.post<String>(url, data: data);
      return Res(res.data);
    }
    on DioException catch(e){
      String? message;
      if(e.type!=DioExceptionType.unknown){
        message = e.message??"未知".tr;
      }else{
        message = e.toString().split("\n").elementAtOrNull(1);
      }
      return Res(null, errorMessage: message??"网络错误");
    }
    catch(e, s){
      LogManager.addLog(LogLevel.error, "Network", "$e\n$s");
      String? message;
      if(e.toString() != "null"){
        message = e.toString();
      }
      return Res(null, errorMessage: message??"网络错误");
    }
  }

  ///获取用户名, 同时用于检测cookie是否有效
  Future<bool> getUserName() async{
    try {
      await cookieJar.deleteAll();
      cookiesStr = "";
      var res = await request("https://forums.e-hentai.org/", headers: {
        "referer": "https://forums.e-hentai.org/index.php?",
        "accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
        "accept-encoding": "gzip, deflate, br",
        "accept-language": "zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7"
      }, expiredTime: CacheExpiredTime.no);
      if (res.error) {
        return false;
      }

      var html = parse(res.data);
      var name = html.querySelector("div#userlinks > p.home > b > a");
      if (name != null) {
        appdata.ehAccount = name.text;
        appdata.writeData();
      } else {
        appdata.ehId = "";
        appdata.ehPassHash = "";
        appdata.igneous = "";
      }
      return name != null;
    }
    catch(e, s){
      LogManager.addLog(LogLevel.error, "Network", "$e\n$s");
      return false;
    }
  }

  ///解析星星的html元素的位置属性, 返回评分
  double getStarsFromPosition(String position){
    int i =0;
    while(position[i]!=";"){
      i++;
      if(i == position.length){
        break;
      }
    }
    switch(position.substring(0,i)){
      case "background-position:0px -1px": return 5;
      case "background-position:0px -21px": return 4.5;
      case "background-position:-16px -1px": return 4;
      case "background-position:-16px -21px": return 3.5;
      case "background-position:-32px -1px": return 3;
      case "background-position:-32px -21px": return 2.5;
      case "background-position:-48px -1px": return 2;
      case "background-position:-48px -21px": return 1.5;
      case "background-position:-64px -1px": return 1;
      case "background-position:-64px -21px": return 0.5;
    }
    return 0.5;
  }

  ///从e-hentai链接中获取当前页面的所有画廊
  Future<Res<Galleries>> getGalleries(String url,{bool leaderboard = false, bool favoritePage=false}) async{
    //从一个链接中获取所有画廊, 同时获得下一页的链接
    //leaderboard比正常的表格多了第一列
    bool ignoreExamination = url.contains("favorites");
    int t = 0;
    if(leaderboard){
      t++;
    }
    var res = await request(url, expiredTime: CacheExpiredTime.no);
    if(res.error){
      return Res(null, errorMessage: res.errorMessage);
    }
    try {
      var document = parse(res.data);
      var items = document.querySelectorAll("table.itg.gltc > tbody > tr");
      var galleries = <EhGalleryBrief>[];
      for (int i = 1; i < items.length; i++) {
        //items的第一个为表格的标题, 忽略
        try {
          var type = items[i].children[0 + t].children[0].text;
          var time = items[i].children[1 + t].children[2].children[0].text;
          var stars = getStarsFromPosition(
              items[i].children[1 + t].children[2].children[1].attributes["style"]!);
          var cover = items[i].children[1 + t].children[1].children[0].children[0]
              .attributes["src"];
          if (cover![0] == 'd') {
            cover =
            items[i].children[1 + t].children[1].children[0].children[0].attributes["data-src"];
          }
          var title = items[i].children[2 + t].children[0].children[0].text;
          var link = items[i].children[2 + t].children[0].attributes["href"];
          String uploader = "";
          try {
            uploader = items[i].children[3 + t].children[0].children[0].text;
          }
          catch (e) {
            //收藏夹页没有uploader
          }
          var tags = <String>[];
          for (var node in items[i].children[2 + t].children[0].children[1].children) {
            tags.add(node.attributes["title"]!);
          }
          galleries.add(EhGalleryBrief(
              title,
              type,
              time,
              uploader,
              cover!,
              stars,
              link!,
              tags,
              ignoreExamination: ignoreExamination
          ));
        }
        catch (e) {
          //表格中存在空行或者被屏蔽
          continue;
        }
      }
      var g = Galleries();
      var nextButton = document.getElementById("dnext");
      if (nextButton == null) {
        g.next = null;
      } else {
        g.next = nextButton.attributes["href"];
      }
      g.galleries = galleries;

      //获取收藏夹名称
      if(favoritePage && appdata.ehAccount != ""){
        var names = <String>[];
        try {
          var folderDivs = document.querySelectorAll("div.fp");
          for (var folderDiv in folderDivs) {
            names.add(folderDiv.children
                .elementAtOrNull(2)
                ?.text ?? "Favorite ${names.length}");
          }
          if(names.length != 10){
            names = names.sublist(0, 10);
          }
          folderNames = names;
        }
        catch(e){
          //忽视
        }
        return Res(g, subData: folderNames);
      }

      return Res(g);
    }
    catch(e, s){
      LogManager.addLog(LogLevel.error, "Data Analysis", "$e\n$s");
      return Res(null, errorMessage: "解析失败: $e");
    }
  }

  ///获取画廊的下一页
  Future<bool> getNextPageGalleries(Galleries galleries) async{
    if(galleries.next==null)  return true;
    var next = await getGalleries(galleries.next!);
    if(next.error)  return false;
    galleries.galleries.addAll(next.data.galleries);
    galleries.next = next.data.next;
    return true;
  }

  ///从漫画详情页链接中获取漫画详细信息
  Future<Res<Gallery>> getGalleryInfo(EhGalleryBrief brief) async{
    try{
      var res = await request("${brief.link}?/hc=1", expiredTime: CacheExpiredTime.no);
      if (res.error){
        return Res(null, errorMessage: res.errorMessage);
      }
      var document = parse(res.data);
      //tags
      var tags = <String, List<String>>{};
      var tagLists = document.querySelectorAll("div#taglist > table > tbody > tr");
      for (var tr in tagLists) {
        var list = <String>[];
        for (var div in tr.children[1].children) {
          list.add(div.children[0].text);
        }
        tags[tr.children[0].text.substring(0, tr.children[0].text.length - 1)] = list;
      }
      //图片链接, 仅加载第一页, 因为无需额外的网络请求, 剩下的进入阅读器加载
      var urls = <String>[];
      String maxPage = "1"; //缩略图列表的最大页数
      var pages = document.querySelectorAll("div.gtb > table.ptb > tbody > tr > td");
      maxPage = pages[pages.length - 2].text;
      try {
        var temp = document;
        var links = temp.querySelectorAll("div#gdt > div.gdtm > div > a");
        for (var link in links) {
          urls.add(link.attributes["href"]!);
        }
        links = temp.querySelectorAll("div#gdt > div.gdtl > a");
        for (var link in links) {
          urls.add(link.attributes["href"]!);
        }
      } catch (e) {
        //获取图片链接失败
        return Res(null, errorMessage: "解析失败: $e");
      }
      bool favorite = true;
      if(document.getElementById("favoritelink")?.text == " Add to Favorites"){
        favorite = false;
      }
      var gallery = Gallery(brief, tags, urls, favorite,maxPage);
      gallery.coverPath = document.querySelector("div#gleft > div#gd1 > div")!.attributes["style"]!;
      gallery.coverPath = RegExp(r"https?://([-a-zA-Z0-9.]+(/\S*)?\.(?:jpg|jpeg|gif|png))").firstMatch(gallery.coverPath)![0]!;
      //评论
      var comments = document.getElementsByClassName("c1");
      for(var c in comments){
        var name = c.getElementsByClassName("c3")[0].getElementsByTagName("a").elementAtOrNull(0)?.text??"未知";
        var time = c.getElementsByClassName("c3")[0].text.substring(11,32);
        var content = c.getElementsByClassName("c6")[0].text;
        gallery.comments.add(Comment(name, content, time));
      }
      //上传者
      var uploader = document.getElementById("gdn")!.children.elementAtOrNull(0)?.text??"未知";
      gallery.uploader = uploader;
      //星星
      var stars =
      getStarsFromPosition(document.getElementById("rating_image")!.attributes["style"]!);
      gallery.stars = stars;
      //平均分数
      gallery.rating = document.getElementById("rating_label")?.text;
      //类型
      var type = document.getElementsByClassName("cs")[0].text;
      gallery.type = type;
      //时间
      var time = document.querySelector("div#gdd > table > tbody > tr > td.gdt2")!.text;
      gallery.time = time;
      //身份认证数据
      gallery.auth = getVariablesFromJsCode(res.data);
      return Res(gallery);
    }
    catch(e, s){
      LogManager.addLog(LogLevel.error, "Data Analysis", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  ///获取图片链接
  ///
  /// 返回值表示成功加载的页数
  /// 返回-1表示加载完成
  /// 返回0表示失败
  Stream<int> loadGalleryPages(Gallery gallery) async*{
    Map<int, List<String>> urls = {};
    int loadingItems = 0;
    int loaded = 0;
    Future<void> loadPage(int p) async{
      loadingItems++;
      try {
        var urls_ = <String>[];
        var temp = parse((await request("${gallery.link}?p=$p")).data);
        var links = temp.querySelectorAll("div#gdt > div.gdtm > div > a");
        for (var link in links) {
          urls_.add(link.attributes["href"]!);
        }
        links = temp.querySelectorAll("div#gdt > div.gdtl > a");
        for (var link in links) {
          urls_.add(link.attributes["href"]!);
        }
        await Future.delayed(const Duration(milliseconds: 100));
        urls[p] = urls_;
        loaded++;
      }
      catch(e){
        rethrow;
      }
      finally{
        loadingItems--;
      }
    }
    int loaded_ = 0;
    bool error = false;
    for (int i = 1; i < int.parse(gallery.maxPage); i++) {
      while(loadingItems > 5){
        await Future.delayed(const Duration(milliseconds: 200));
      }
      if(loaded_ != loaded){
        yield loaded;
        loaded_ = loaded;
      }
      loadPage(i).onError((e, stackTrace) => error = true);
      if(error){
        yield 0;
        return;
      }
    }
    while(loadingItems != 0){
      await Future.delayed(const Duration(milliseconds: 200));
      if(error){
        yield 0;
        return;
      }
    }
    for (int i = 1; i < int.parse(gallery.maxPage); i++){
      gallery.urls.addAll(urls[i]!);
    }
    yield -1;
  }

  ///搜索e-hentai
  Future<Res<Galleries>> search(String keyword) async{
    if(keyword!=""){
      appdata.searchHistory.remove(keyword);
      appdata.searchHistory.add(keyword);
      appdata.writeHistory();
    }
    var res =  await getGalleries("$ehBaseUrl/?f_search=$keyword");
    Future.delayed(const Duration(microseconds: 500),(){
      try{
        Get.find<PreSearchController>().update();
      }
      catch(e){
        //忽视
      }
    });
    return res;
  }

  ///获取排行榜
  Future<Res<EhLeaderboard>> getLeaderboard(EhLeaderboardType type) async{
    var res = await getGalleries("https://e-hentai.org/toplist.php?tl=${type.value}",leaderboard: true);
    if(res.error) return Res(null, errorMessage: res.errorMessage);
    return Res(EhLeaderboard(type, res.data.galleries, 0));
  }

  ///获取排行榜的下一页
  Future<void> getLeaderboardNextPage(EhLeaderboard leaderboard) async{
    if(leaderboard.loaded == EhLeaderboard.max){
      return;
    }else{
      var res = await getGalleries("$ehBaseUrl/toplist.php?tl=${leaderboard.type.value}&p=${leaderboard.loaded+1}",leaderboard: true);
      if(!res.error){
        leaderboard.galleries.addAll(res.data.galleries);
      }
      leaderboard.loaded++;
    }
  }

  ///评分
  Future<bool> rateGallery(Map<String, String> auth, int rating) async{
    var res = await apiRequest({
      "method": "rategallery",
      "apiuid": auth["apiuid"],
      "apikey": auth["apikey"],
      "gid": auth["gid"],
      "token": auth["token"],
      "rating": rating
    });
    return !res.error;
  }

  ///收藏
  Future<bool> favorite(String gid, String token, {String id = "0"}) async{
    var res = await post(
      "https://e-hentai.org/gallerypopups.php?gid=$gid&t=$token&act=addfav",
      "favcat=$id&favnote=&apply=Add+to+Favorites&update=1",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded"
      }
    );
    if(res.error){
      return false;
    }
    if(res.error || res.data.isEmpty || res.data[0] != "<"){
      return false;
    }else {
      return true;
    }
  }

  ///取消收藏
  Future<bool> unfavorite(String gid, String token) async{
    var res = await post(
      "https://e-hentai.org/gallerypopups.php?gid=$gid&t=$token&act=addfav",
      "favcat=favdel&favnote=&apply=Apply+Changes&update=1",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded"
      }
    );
    if(res.error || res.data[0] != "<"){
      return false;
    }else {
      return true;
    }
  }

  ///发送评论
  Future<Res<bool>> comment(String content, String link) async{
    var res = await post(
      link,
      "commenttext_new=${Uri.encodeComponent(content)}",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded"
      }
    );
    if(res.error){
      return Res(null, errorMessage: res.errorMessage);
    }
    var document = parse(res.data);
    if(document.querySelector("p.br") != null){
      return Res(null,errorMessage: document.querySelector("p.br")!.text);
    }
    return Res(true);
  }
}