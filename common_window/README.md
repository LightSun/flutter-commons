# flutter_common_window
[![pub package](https://img.shields.io/pub/v/flutter_common_window.svg)](https://pub.dev/packages/flutter_common_window)
a common overlap window for flutter. support animation, anchor left/right/top/bottom.

## demo
 ![demo1](https://github.com/LightSun/flutter-commons/blob/master/assets/flutter_common_window.gif)
## simple progress-dialog
* 1, create window.
```dart
_loadingWindow = new Window((BuildContext context){
      return BaseWindow.of(context, _buildLoadingWidget(context),
          top: MediaQuery.of(context).size.height * 2 / 5);
    });
Widget _buildLoadingWidget(BuildContext context) {
       return Center(
         child: Column(
           children: <Widget>[
             CircularProgressIndicator()
           ],
         ),
       );
    }
```
* 2, show
```dart
 _loadingWindow.show(context);
```
* 3,dismiss
```dart
 _loadingWindow.dismiss();
```
* 4, toggle show.
```dart
//if it is shown -> dismiss. if it is not shown ->show
_loadingWindow.toggleShow(context);
```
* 5, dispose
```dart
 _loadingWindow.dispose();
```

## simple toast with animation
* 1, setup.
``` dart
  AnimationController controller;
  Animation<Offset> animation;
  Window _toastWindow;

  void initState() {
     super.initState();
      controller = new AnimationController(
             vsync: this, duration: const Duration(seconds: 2));
      animation = Tween(begin: Offset.zero, end: Offset(0.0, 10)).animate(controller);
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
 }
  @override
   void dispose() {
     _toastWindow.dispose();
     controller.dispose();
     super.dispose();
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
```
* 2, show toast with extra duration 2000(exclude animate time).
```dart
_toastWindow.toggleShow(context, showTimeMsec: 2000);
```
## anchor window
* 1, create correct widget.
```dart
...
Window _anchorBottomWindow;
GlobalKey _anchorKey = GlobalKey();
...
 Widget build(BuildContext context) {
 ......
 Container(
                color: Colors.yellowAccent,
                margin: EdgeInsets.fromLTRB(20, 0, 50, 0),
                child: ListTile(
                    key: _anchorKey,
                    title: Text("Anchor window-bottom"),
                    onTap: () {
                      _showBottomWindow();
                    })
            ),
   ......
 }
```
* 2, show
```dart
void _showBottomWindow(){
    if(_anchorBottomWindow == null){
      _anchorBottomWindow = Window.ofAnchor(context, _anchorKey, _buildToastImpl(context));
    }
    _anchorBottomWindow.toggleShow(context);
}
```
*3, dismiss and dispose same as above.

### The more to see . in 'example/main.dart'
## Anchor
* Heaven7