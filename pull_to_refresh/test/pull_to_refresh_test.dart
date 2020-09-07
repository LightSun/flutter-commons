import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pull_to_refresh/libs.dart';

import 'package:pull_to_refresh/pull_to_refresh.dart';

void main() {
    runApp(PullToRefreshApp());
}


class PullToRefreshApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'PullToRrFresh api Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: PullToRefreshWidget(
          _createListHelper(),
          _buildError,
          _buildEmpty,
          _buildContent, _buildItem, _buildLoadMore
      ),
    );
  }
  ListHelper _createListHelper(){
     PageManager pm = new PageManager(_repository, _interceptor);
     return ListHelper()
       ..pageManager = pm
       ..context = null // for mock no need context
      ..callback = ListCallback();
  }
  void _repository(Object context, Map<String, dynamic> params, bool refresh,
      OnResult result,
      {OnException e}) {
    //just mock load data
    int count = params["pageNo"];
    if(count % 5 == 0){
       Future.delayed(new Duration(milliseconds: 500)).then((value){
           e.call(context, params, refresh, new Exception("mocked exception message."));
       });
    }else if(count % 5 == 4){
      //mock empty
      Future.delayed(new Duration(milliseconds: 500)).then((value){
        result.call(context, params, refresh, new List());
      });
    }else{
      Future.delayed(new Duration(milliseconds: 500)).then((value){
        result.call(context, params, refresh, List.generate(10, (index) => index));
      });
    }
  }

  Map _interceptor(Map map) {
    map.putIfAbsent("label", () => "全部");
    return map;
  }

  Widget _buildLoadMore(BuildContext context, bool isPerformingRequest, FooterState fs) {
    return _buildProgressIndicator(isPerformingRequest, fs);
  }

  Widget _buildItem(BuildContext context, int index, dynamic item) {
    //return ListTile(title: new Text("Number $index"));
    return new Container(
      margin: EdgeInsets.all(15.0),
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Text("Sample title: \n$index", textAlign: TextAlign.start,
          ),
          new Text(
            "Sample desc: \n$index", textAlign: TextAlign.start,),
          new Container(
            margin: EdgeInsets.only(top: 10.0),
            child: new Divider(
              height: 2.0,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, Widget refreshIndicator, bool iosStyle) {
    return Scaffold(
      body: Container(padding: EdgeInsets.all(2.0), child: refreshIndicator),
    );
  }

  Widget _buildEmpty(BuildContext context, bool reset, VoidCallback refresh) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(2.0),
        alignment: Alignment.center,
        child: RefreshIndicator(
          onRefresh: refresh,
          backgroundColor: Colors.white70,
          color: Colors.pinkAccent,
          child: _buildEmptyWidget2(context),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, bool reset, VoidCallback refresh) {
    return Scaffold(
        body: Container(
          padding: EdgeInsets.all(2.0),
          child: _buildErrorWidget(context, refresh),
        ));
  }

  //--------------------------------------------------------
  Widget _buildProgressIndicator(bool isPerformingRequest, FooterState fs) {
    switch(fs){
      case FooterState.STATE_NORMAL:
      case FooterState.STATE_LOADING:
        return new Padding(
          padding: const EdgeInsets.all(8.0),
          child: new Center(
            child: new Opacity(
              opacity: isPerformingRequest ? 1.0 : 0.0,
              //opacity: 1.0 ,
              child: new CircularProgressIndicator(
                backgroundColor: Colors.black,
                valueColor: AlwaysStoppedAnimation(Colors.deepOrange),
              ),
            ),
          ),
        );

      case FooterState.STATE_THE_END:
        return new Padding(
          padding: const EdgeInsets.all(8.0),
          child: new Center(
            child: ListTile(title: new Text("--- The end ---"))
          ),
        );

      case FooterState.STATE_NET_ERROR:
        //not used current
        break;
    }
  }

  Widget _buildEmptyWidget2(BuildContext context) {
    return ListView(
      children: <Widget>[
        Image.network(
          "https://ss0.bdstatic.com/70cFuHSh_Q1YnxGkpoWK1HF6hhy/it/u=1946244045,749707381&fm=26&gp=0.jpg",
          scale: 2,
        ),
        Text("暂无数据(No data)",
            textAlign: TextAlign.center,
            style: TextStyle(
              backgroundColor: Colors.blue,
              color: Colors.white,
            ))
      ],
      physics: AlwaysScrollableScrollPhysics(),
    );
  }

  Widget _buildErrorWidget(BuildContext context, VoidCallback refresh) {
    return Column(
      children: <Widget>[
        Image.network(
            "https://ss0.bdstatic.com/70cFuHSh_Q1YnxGkpoWK1HF6hhy/it/u=1946244045,749707381&fm=26&gp=0.jpg",
            scale: 2),
        GestureDetector(
          child: Text(
            "重新加载(reload)",
            style: TextStyle(
              backgroundColor: Colors.blue,
              color: Colors.white,
            ),
          ),
          onTap: refresh,
        )
      ],
    );
  }
}