import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_common_window/pkg/base_window.dart';

class BaseWindowDemoApps extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'PullToRrFreshApp Demo',
        theme: ThemeData(
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or simply save your changes to "hot reload" in a Flutter IDE).
          // Notice that the counter didn't reset back to zero; the application
          // is not restarted.
          primarySwatch: Colors.blue,
          // This makes the visual density adapt to the platform that you run
          // the app on. For desktop platforms, the controls will be smaller and
          // closer together (more dense) than on mobile platforms.
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: HomeDemo()
    );
  }
}
class HomeDemo extends StatefulWidget {
  @override
  State createState() {
     return _HomeState();
  }
}
class _HomeState extends State<HomeDemo> with TickerProviderStateMixin  {

  AnimationController controller;//动画控制器
  Animation<Offset> animation;
 // CurvedAnimation curved;//曲线动画，动画插值，
  double _toastTop = 0;

  Window _toastWindow;
  Window _loadingWindow;
  Window _anchorBottomWindow;

  GlobalKey _anchorKey = GlobalKey();
  GlobalKey _anchorKey2 = GlobalKey();
  GlobalKey _anchorKey3 = GlobalKey();
  GlobalKey _anchorKey4 = GlobalKey();
  GlobalKey _anchorKey5 = GlobalKey();
  GlobalKey _anchorKey6 = GlobalKey();
  GlobalKey _anchorKey7 = GlobalKey();
  GlobalKey _anchorKey8 = GlobalKey();

  @override
  void initState() {
    super.initState();
    _toastWindow = new Window((BuildContext context){
      return BaseWindow.of(context, _buildToastWidget(context),
          top: _toastTop,showCallback: (bool){
              if(bool){
                return controller.forward(from: 0.0);
              }
              return Future.value();
          }, dismissDelegate: () =>
             controller.reverse());
    });
    _loadingWindow = new Window((BuildContext context){
      return BaseWindow.of(context, _buildLoadingWidget(context),
          top: _buildToastPosition(context, Position.center));
    });
    //anim of toast
    controller = new AnimationController(
        vsync: this, duration: const Duration(seconds: 2));
    animation = Tween(begin: Offset.zero, end: Offset(0.0, 10)).animate(controller);
  }
  @override
  void dispose() {
    _toastWindow.dispose();
    _loadingWindow.dispose();
    if(_anchorBottomWindow != null){
      _anchorBottomWindow.dispose();
    }
    controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text("Base window demos"),
        centerTitle: true,
        leading: IconButton(
          //icon: Image.asset("aasets/images/arrow_right.png"),
          icon:  Icon(Icons.add_box),
          onPressed: (){

          },
        ),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        widthFactor: 10,
        child: ListView(
          children: <Widget>[
            ListTile(title: Text("Toast"),
              onTap: () {
                _toastWindow.toggleShow(context, showTimeMsec: 2000);
              }),
            ListTile(title: Text("LoadingDialog"),
                onTap: () {
                  _loadingWindow.toggleShow(context);
                }),
            Container(
                color: Colors.deepOrangeAccent,
                margin: EdgeInsets.fromLTRB(100, 0, 100, 0),
                child: ListTile(
                    key: _anchorKey8,
                    title: Text("Anchor window-right"),
                    onTap: () {
                      if(_anchorBottomWindow == null){
                        _anchorBottomWindow = Window.ofAnchor(context, _anchorKey8,
                            _buildToastImpl(context, text: "Text")
                            , showPos: RelativePosition.RIGHT);
                      }
                      _anchorBottomWindow.toggleShow(context);
                    })
            ),
            Container(
                color: Colors.blue,
                margin: EdgeInsets.fromLTRB(100, 0, 100, 0),
                child: ListTile(
                    key: _anchorKey6,
                    title: Text("Anchor window-left"),
                    onTap: () {
                      if(_anchorBottomWindow == null){
                        _anchorBottomWindow = Window.ofAnchor(context, _anchorKey6,
                            _buildToastImpl(context, text: "Text")
                            , showPos: RelativePosition.LEFT);
                      }
                      _anchorBottomWindow.toggleShow(context);
                    })
            ),
            Container(
                color: Colors.yellowAccent,
                margin: EdgeInsets.fromLTRB(20, 0, 50, 0),
                child: ListTile(
                    key: _anchorKey,
                    title: Text("Anchor window-bottom"),
                    onTap: () {
                      if(_anchorBottomWindow == null){
                        _anchorBottomWindow = Window.ofAnchor(context, _anchorKey, _buildToastImpl(context));
                      }
                      _anchorBottomWindow.toggleShow(context);
                    })
            ),
            Container(
                color: Colors.yellowAccent,
                margin: EdgeInsets.fromLTRB(50, 0, 20, 0),
                child: ListTile(
                    key: _anchorKey2,
                    title: Text("Anchor window-bottom2"),
                    onTap: () {
                      if(_anchorBottomWindow == null){
                        _anchorBottomWindow = Window.ofAnchor(context, _anchorKey2, _buildToastImpl(context));
                      }
                      _anchorBottomWindow.toggleShow(context);
                    })
            ),
            Container(
                color: Colors.pinkAccent,
                margin: EdgeInsets.fromLTRB(50, 0, 20, 0),
                child: ListTile(
                    key: _anchorKey3,
                    title: Text("Anchor window-top"),
                    onTap: () {
                      if(_anchorBottomWindow == null){
                        _anchorBottomWindow = Window.ofAnchor(context, _anchorKey3, _buildToastImpl(context)
                              , showPos: RelativePosition.TOP);
                      }
                      _anchorBottomWindow.toggleShow(context);
                    })
            ),
            Container(
                color: Colors.pinkAccent,
                margin: EdgeInsets.fromLTRB(20, 0, 50, 0),
                child: ListTile(
                    key: _anchorKey4,
                    title: Text("Anchor window-top"),
                    onTap: () {
                      if(_anchorBottomWindow == null){
                        _anchorBottomWindow = Window.ofAnchor(context, _anchorKey4, _buildToastImpl(context)
                            , showPos: RelativePosition.TOP);
                      }
                      _anchorBottomWindow.toggleShow(context);
                    })
            ),
            Container(
                color: Colors.blue,
                margin: EdgeInsets.fromLTRB(100, 0, 100, 0),
                child: ListTile(
                    key: _anchorKey5,
                    title: Text("Anchor window-left"),
                    onTap: () {
                      if(_anchorBottomWindow == null){
                        _anchorBottomWindow = Window.ofAnchor(context, _anchorKey5,
                            _buildToastImpl(context, text: "Text")
                            , showPos: RelativePosition.LEFT);
                      }
                      _anchorBottomWindow.toggleShow(context);
                    })
            ),
            Container(
                color: Colors.deepOrangeAccent,
                margin: EdgeInsets.fromLTRB(100, 0, 100, 0),
                child: ListTile(
                    key: _anchorKey7,
                    title: Text("Anchor window-right"),
                    onTap: () {
                      if(_anchorBottomWindow == null){
                        _anchorBottomWindow = Window.ofAnchor(context, _anchorKey7,
                            _buildToastImpl(context, text: "Text")
                            , showPos: RelativePosition.RIGHT);
                      }
                      _anchorBottomWindow.toggleShow(context);
                    })
            ),
            Container(
              color: Colors.purple,
              padding: EdgeInsets.fromLTRB(100, 0, 100, 0),
              child:  ListTile(title: Text("Dispose all window"),
                  onTap: () {
                    _disposeAllWindow();
                  }),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){

        },
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
  void _disposeAllWindow(){
     if(_anchorBottomWindow != null){
       _anchorBottomWindow.dispose();
       _anchorBottomWindow = null;
     }
     if(_toastWindow != null){
       _toastWindow.dismiss();
     }
     if(_loadingWindow != null){
       _loadingWindow.dismiss();
     }
  }

  Widget _buildToastWidget(BuildContext context) {
    return SlideTransition(
        position: animation,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.0),
          child: _buildToastImpl(context),
        )
    );
  }
}

Widget _buildLoadingWidget(BuildContext context) {
   return Center(
     child: Column(
       children: <Widget>[
         CircularProgressIndicator()
       ],
     ),
   );
}

Widget _buildToastImpl(BuildContext context,{text}) {
  text ??="test show toast by BaseWindow";
  return Center(
    child: Card(
      color: Colors.black,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ),
    ),
  );
}
enum Position{
  top,
  center,
  bottom,
}
double _buildToastPosition(BuildContext context, Position _position) {
  var backResult;
  if (_position == Position.top) {
    backResult = MediaQuery.of(context).size.height * 1 / 4;
  } else if (_position == Position.center) {
    backResult = MediaQuery.of(context).size.height * 2 / 5;
  } else {
    backResult = MediaQuery.of(context).size.height * 3 / 4;
  }
  return backResult;
}