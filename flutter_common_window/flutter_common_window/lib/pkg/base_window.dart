import 'package:flutter/widgets.dart';

typedef ShowCallback = Future Function(bool);
typedef DismissDelegate = Future Function();

class _PendingAction{
  int showTimeMsec = -1;
  OverlayEntry below;
  OverlayEntry above;
}
///the pending work mode for show.
enum WorkMode{
  /// when show is called, but window is pending. this request will be dropped.
  DROP,
  /// hen show is called, but window is pending. this request will cause dismiss and then continue show.
  DISMISS_BEFORE,
  /// hen show is called, but window is pending. this request will cause [DismissDelegate] call and then continue show.
  DISMISS_DELEGATE_BEFORE
}

class BaseWindow {
  OverlayEntry _overlayEntry;
  BuildContext _context;
  bool _showing = false;
  final ShowCallback _showCallback;
  final DismissDelegate _dismissDelegate;
  bool _pending = false;

  final WorkMode _mode;
  _PendingAction _pendingAction;

  OverlayEntry get overlayEntry => _overlayEntry;
  BuildContext get buildContext => _context;

  //private constructor
  BaseWindow._(this._context, this._overlayEntry, this._showCallback, this._dismissDelegate, this._mode);

  ///
  /// create base window by context , widget and callback.
  /// * context: the build context
  /// * child: the widget to display
  /// * top: margin top for this window to show. if < 0 means, use child to show directly, or else use Positioned.
  /// * showCallback: callback on shown or not.return a [Future].
  /// * dismissDelegate: called when you want to dismiss window.
  /// eg: animation. you should return a [Future].
  ///
  factory BaseWindow.of(BuildContext context, Widget child,
      { WorkMode mode = WorkMode.DISMISS_BEFORE,
        double top = 0.0,
        showCallback,
        dismissDelegate}) {
    //AnimatedOpacity
    OverlayEntry entry = OverlayEntry(
        builder: (BuildContext context) => top >= 0 ? Positioned(
              //top effect the position of widget
              top: top,
              child: Container(
                  alignment: Alignment.center,
                  width: MediaQuery.of(context).size.width,
                  child: child),
            ) :
        child
    );
    return BaseWindow._(context, entry, showCallback, dismissDelegate, mode);
  }

  ///
  /// show the window right-now.
  /// * showTimeMsec: if you want to auto-dismiss window. you may set this value.
  /// * below:  the below [OverlayEntry].
  /// * above: the above [OverlayEntry].
  void show({int showTimeMsec = -1, OverlayEntry below, OverlayEntry above}) async{
    assert(!isDisposed());
    if(_pending){
      switch(_mode){
        case WorkMode.DROP:
          return;

        case WorkMode.DISMISS_BEFORE:
          _pendingAction = new _PendingAction()
            ..showTimeMsec = showTimeMsec
            ..below = below
            ..above = above;
          _showing = false;
          _dismissImpl();
          return;

        case WorkMode.DISMISS_DELEGATE_BEFORE:
          _pendingAction = new _PendingAction()
            ..showTimeMsec = showTimeMsec
            ..below = below
            ..above = above;
          dismiss();
          return;
      }
      print("_pendingDismiss = true. drop this request.");
      return;
    }
    OverlayState overlayState = Overlay.of(_context);
    //overlap on top
    _showing = true;
    overlayState.insert(_overlayEntry, below: below, above: above);
    Future future;
    if (_showCallback != null) {
      future = _showCallback.call(true);
    }
    //if has show time. auto-dismiss
    if(showTimeMsec > 0){
      if(future != null) {
        _pending = true;
        future.then((value) async {
          if(_pending){
            _pending = false;
            await Future.delayed(Duration(milliseconds: showTimeMsec));
            dismiss();
          }
        });
      }else{
        await Future.delayed(Duration(milliseconds: showTimeMsec));
        dismiss();
      }
    }
  }

  /// markNeedsBuild
  void markNeedsBuild() {
    if (_overlayEntry != null) {
      _overlayEntry.markNeedsBuild();
    }
  }

  /// dismiss base window
  /// * useDelegate: use dismiss delegate or not
  void dismiss({bool useDelegate = true}) {
    if (_showing) {
      _showing = false;
      if(useDelegate && _dismissDelegate != null){
        _pending = true;
        _dismissDelegate.call().then((value) {
          if(_pending){
            _dismissImpl();
          }
        });
      }else{
        _dismissImpl();
      }
    }
  }
  void _dismissImpl(){
    _pending = false;
    if (_overlayEntry != null) {
      _overlayEntry.remove();
    }
    if (_showCallback != null) {
      _showCallback.call(false);
    }
    if(_pendingAction != null){
      final _PendingAction ac = _pendingAction;
      _pendingAction = null;
      show(showTimeMsec: ac.showTimeMsec,
          below: ac.below,
          above: ac.above);
    }
  }
  /// is pending showing or dismiss.
  bool isPending() => _pending;
  /// is shown or not
  bool isShown() => _showing;
  /// is disposed or not
  bool isDisposed() => _context == null;

  /// dispose
  void dispose() {
    dismiss(useDelegate: false);
    _overlayEntry = null;
    _context = null;
  }
}

typedef WindowCreator = BaseWindow Function(BuildContext context);

enum RelativePosition{
    LEFT, TOP, RIGHT, BOTTOM
}
/// the window wrapper for [BaseWindow]
class Window {
  final WindowCreator _creator;
  BaseWindow _window;

  /// create window by creator
  Window(this._creator);

  BaseWindow baseWindow(BuildContext context) => _window ??= _creator.call(context);

  /// show the window
  /// * context: the context
  /// * showTimeMsec: display time mill-second for auto dismiss
  /// * below: the below [OverlayEntry]
  /// * above: the above [OverlayEntry]
  void show(BuildContext context,
      {int showTimeMsec = -1, OverlayEntry below,
      OverlayEntry above}) {
    baseWindow(context).show(showTimeMsec: showTimeMsec, below: below, above: above);
  }
  /// indicate the window is shown or not
  bool isShown() => _window != null && _window.isShown();

  /// dispose the window
  void dispose() {
    if (_window != null) {
      _window.dispose();
      _window = null;
    }
  }

  /// dismiss the window, but not dispose.
  void dismiss({bool useDelegate = true}) {
    if (_window != null) {
      _window.dismiss(useDelegate: useDelegate);
    }
  }

  /// toggle show state of window.
  void toggleShow(BuildContext context,
      {int showTimeMsec = -1, OverlayEntry below,
      OverlayEntry above}) {
    if (isShown()) {
      _window.dismiss();
    } else {
      baseWindow(context).show(showTimeMsec: showTimeMsec, below: below,above: above);
    }
  }

  /// create window by child and anchor.
  /// * context: the context
  /// * anchor: the anchor key
  /// * child: the child expect to display
  /// * showPos: The relative position of the child relative to anchor
  /// * offsetX: the x offset. which used for 'showPos = LEFT' or 'showPos = RIGHT'
  /// * offsetY: the y offset. which used for 'showPos = TOP' or 'showPos = BOTTOM'
  /// * mode: work mode for if window already display
  /// * showCallback: show callback . can used for appear animation
  /// * dismissDelegate: dismiss delegate. can used for disappear animation
  factory Window.ofAnchor(BuildContext context, GlobalKey anchor, Widget child,
      { RelativePosition showPos = RelativePosition.BOTTOM,
        double offsetX = 0.0, //offset distance. only effect- LEFT-RIGHT
        double offsetY = 0.0, //offset distance.

        WorkMode mode = WorkMode.DISMISS_BEFORE,
        showCallback,
        dismissDelegate
      }){
    RenderBox renderBox = anchor.currentContext.findRenderObject();
    //print("paintBounds: ${renderBox.paintBounds}"); // margin also contains
    Offset topOffset = renderBox.localToGlobal(Offset.zero);
    Offset bottomOffset = renderBox.localToGlobal(Offset(renderBox.size.width, renderBox.size.height));
    double left = topOffset.dx;
    double top = topOffset.dy;
    double bottom = bottomOffset.dy;
    double right = bottomOffset.dx;
    //print("left = $left, top =$top, right = $right, bottom = $bottom");
    //compute the best left.
    Size screenSize = MediaQuery.of(context).size;
    //left-space
    double rightSpace = screenSize.width - right;
    double bottomSpace = screenSize.height - bottom;

    Widget realChild;

    double rTopPos, rLeftPos, rRightPos, rBottomPos;
    Alignment align;
    switch(showPos){
      case RelativePosition.BOTTOM:
        rTopPos = bottom + offsetY;
        //make widget align center by anchor
        if(left >= rightSpace){
          rLeftPos = (left - rightSpace) ;

          realChild = Positioned(
            top: rTopPos,
            left: rLeftPos,
            child: Container(
                width: screenSize.width - rLeftPos,
                alignment: Alignment.topCenter,
                child: child),
          );
        }else{
          rRightPos = screenSize.width - (right + left);
         // print("rRightPos = $rRightPos");
          realChild = Positioned(
            top: rTopPos,
            //Note: right position is not the absolute position of screen just the relative pos
            right: rRightPos,
            child: Container(
                width: screenSize.width - rRightPos,
                alignment: Alignment.topCenter,
                child: child),
          );
        }
        break;

      case RelativePosition.TOP:
        align = Alignment.bottomCenter;
        rBottomPos = screenSize.height - top - offsetY;
        if(left >= rightSpace){
          rLeftPos = (left - rightSpace);
          realChild = Positioned(
            bottom: rBottomPos,
            left: rLeftPos,
            child: Container(
                width: screenSize.width - rLeftPos,
                alignment: align,
                child: child),
          );
        }else{
          rRightPos = screenSize.width - (right + left);
          realChild = Positioned(
            bottom: rBottomPos,
            right: rRightPos,
            child: Container(
                width: screenSize.width - rRightPos,
                alignment: align,
                child: child),
          );
        }
        break;

      case RelativePosition.LEFT:
        rRightPos = screenSize.width - left + offsetX;
        if(top >= bottomSpace){
          rTopPos = top - bottomSpace;
          realChild = Positioned(
            right: rRightPos,
            top: rTopPos,
            child: Container(
              height: screenSize.height - rTopPos,
              alignment: Alignment.centerRight,
              child: child),
          );
        }else{
          rBottomPos = screenSize.height - (bottom + top);
          realChild = Positioned(
            right: rRightPos,
            bottom: rBottomPos,
            child: Container(
                height: screenSize.height - rBottomPos,
                alignment: Alignment.centerRight,
                child: child),
          );
        }
        break;

      case RelativePosition.RIGHT:
        rLeftPos = right + offsetX;
        if(top >= bottomSpace){
          rTopPos = top - bottomSpace;
          realChild = Positioned(
            left: rLeftPos,
            top: rTopPos,
            child: Container(
                height: screenSize.height - rTopPos,
                alignment: Alignment.centerLeft,
                child: child),
          );
        }else{
          rBottomPos = screenSize.height - (bottom + top);
          realChild = Positioned(
            left: rLeftPos,
            bottom: rBottomPos,
            child: Container(
              height: screenSize.height - rBottomPos,
              alignment: Alignment.centerLeft,
              child: child),
          );
        }
        break;

      default:
        throw new Exception("wrong position = $showPos");
    }
    return Window((context) => BaseWindow.of(context, realChild,
        top: -1.0,
        mode: mode,
        showCallback: showCallback,
        dismissDelegate: dismissDelegate));
  }
}
