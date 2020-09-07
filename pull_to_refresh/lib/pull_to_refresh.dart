import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'CupertinoSliverRefresh2.dart';
import 'list_loader.dart';

typedef UiCallbackBuilder = UiCallback Function(PullToRefreshState s);

/// pull-to-refresh widget
class PullToRefreshWidget extends StatefulWidget {
  final ListHelper listHelper;
  final WidgetBuilder errorBuilder;
  final WidgetBuilder emptyBuilder;
  final ContentWidgetBuilder contentBuilder;
  final ItemBuilder itemBuilder;
  final LoadMoreBuilder loadMoreBuilder;

  final Color indicatorBg;
  final Color indicatorValue;
  final ShowLoadMore showLoadMore;
  final double pullUpExtent;

  final RefreshControlIndicatorBuilder iosBuilder;
  final double refreshTriggerPullDistance;
  final double refreshIndicatorExtent;

  /// create pull-to-refresh widget
  /// * helper: the list helper
  /// * empty: the empty widget builder
  /// * error: the error widget builder
  /// * contentBuilder: the content widget builder
  /// * itemBuilder: the item Builder
  /// * loadMoreBuilder: the load more builder
  /// * indicatorBg: the indicator background color of refresh
  /// * indicatorValue: the indicator value color of refresh
  /// * showLoadMore: the function to show load more
  const PullToRefreshWidget(
    this.listHelper,
    this.errorBuilder,
    this.emptyBuilder,
    this.contentBuilder,
    this.itemBuilder,
    this.loadMoreBuilder, {
    this.pullUpExtent = 10,
    this.indicatorBg,
    this.indicatorValue,
    this.showLoadMore,
    this.iosBuilder,
    this.refreshTriggerPullDistance = 100,
    this.refreshIndicatorExtent = 60,
  });

  @override
  PullToRefreshState createState() {
    return PullToRefreshState(
      listHelper,
      emptyBuilder,
      errorBuilder,
      contentBuilder,
      itemBuilder,
      loadMoreBuilder,
      indicatorBg: indicatorBg,
      indicatorValue: indicatorValue,
      showLoadMore: showLoadMore,
      pullUpExtent: pullUpExtent,
      iosBuilder: iosBuilder,
      refreshIndicatorExtent: refreshIndicatorExtent,
      refreshTriggerPullDistance: refreshTriggerPullDistance,
    );
  }
}

class SimpleUiCallback extends UiCallback {
  final PullToRefreshState _state;
  final UiCallback _base;

  SimpleUiCallback(this._state, this._base);

  @override
  void markRefreshing() {
    _state.update(() {
      _state._showRefresh();
      if (_base != null) {
        _base.markRefreshing();
      }
    });
  }

  @override
  void setRequesting(bool requesting,
      {bool clearItems, bool resetError, bool resetEmpty, bool loadMore}) {
    _state.update(() {
      if (clearItems) {
        _state.items.clear();
      }
      _state._footerState =
          loadMore ? FooterState.STATE_LOADING : FooterState.STATE_NORMAL;
      _state._resetEmpty = resetEmpty;
      _state._resetError = resetError;
      _state._isPerformingRequest = requesting;
      if (_base != null) {
        _base.setRequesting(requesting,
            clearItems: clearItems,
            resetError: resetError,
            resetEmpty: resetEmpty);
      }
    });
  }

  @override
  void showContent(List data, FooterState state) {
    _state.update(() {
      _state.items.addAll(data);
      _state._isPerformingRequest = false;
      _state._footerState = state;
      if (_base != null) {
        _base.showContent(data, state);
      }
    });
  }

  @override
  void showEmpty(data) {
    _state.update(() {
      _state._showState = RefreshState.STATE_EMPTY;
      _state._isPerformingRequest = false;
      if (_base != null) {
        _base.showEmpty(data);
      }
    });
  }

  @override
  void showError(Exception e, bool clearItems) {
    _state.update(() {
      if (clearItems) {
        _state.items.clear();
      }
      _state._showState = RefreshState.STATE_ERROR;
      _state._isPerformingRequest = false;
      if (_base != null) {
        _base.showError(e, clearItems);
      }
    });
  }
}

typedef WidgetBuilder = Widget Function(
    BuildContext context, bool reset, VoidCallback refresh);
typedef ContentWidgetBuilder = Widget Function(
    BuildContext context, Widget refreshIndicator, bool iosStyle);
typedef LoadMoreBuilder = Widget Function(
    BuildContext context, bool isPerformingRequest, FooterState fs);
typedef ItemBuilder = Widget Function(
    BuildContext context, int index, dynamic item);
typedef ShowLoadMore = void Function(ScrollController sc);

enum RefreshState {
  STATE_ERROR,
  STATE_EMPTY,
  STATE_NORMAL,
}

class PullToRefreshState extends State<StatefulWidget> {
  /// list load helper.
  ListHelper _helper;

  /// the list data
  final List items = List();

  /// the scroll controller
  final ScrollController _scrollController = new ScrollController();

  /// true if requesting
  bool _isPerformingRequest = false;

  /// show state: normal. error, empty
  RefreshState _showState = RefreshState.STATE_NORMAL;

  /// footer state
  FooterState _footerState = FooterState.STATE_NORMAL;

  /// refresh key, used to show refresh
  GlobalKey<CupertinoSliverRefreshControlState> _refreshKeyIos;
  GlobalKey<RefreshIndicatorState> _refreshKey;

  /// the empty widget builder
  WidgetBuilder _empty;

  /// the error widget builder
  WidgetBuilder _error;

  /// the content widget builder
  ContentWidgetBuilder _contentWidgetBuilder;

  /// the load more builder
  LoadMoreBuilder _loadMoreBuilder;

  /// the item builder
  ItemBuilder _itemBuilder;

  /// the function to show footer as load-more
  ShowLoadMore _showLoadMore;

  /// the indicator background color of refresh
  Color _indicatorBg;

  /// the indicator value color of refresh
  Color _indicatorValue;

  /// true if reset error
  bool _resetError;

  /// true if reset empty
  bool _resetEmpty;

  /// the extent for trigger pull-up. as the delta value from maxScrollExtent.
  double _pullUpExtent;

//----------------------------- ios ----------------------
  /// if is ios style
  RefreshControlIndicatorBuilder _iosBuilder;

  /// The amount of space the refresh indicator sliver will keep holding while
  /// [onRefresh]'s [Future] is still running.
  ///
  /// Must not be null and must be positive, but can be 0.0, in which case the
  /// sliver will start retracting back to 0.0 as soon as the refresh is started.
  /// Defaults to 60px when not specified.
  ///
  /// Must be smaller than [refreshTriggerPullDistance], since the sliver
  /// shouldn't grow further after triggering the refresh.
  double refreshTriggerPullDistance;

  /// A builder that's called as this sliver's size changes, and as the state
  /// changes.
  ///
  /// A default simple Twitter-style pull-to-refresh indicator is provided if
  /// not specified.
  ///
  /// Can be set to null, in which case nothing will be drawn in the overscrolled
  /// space.
  ///
  /// Will not be called when the available space is zero such as before any
  /// overscroll.
  double refreshIndicatorExtent;

//------------------------------ end ios --------------------------------

  /// create refresh state
  /// * helper: the list helper
  /// * empty: the empty widget builder
  /// * error: the error widget builder
  /// * contentBuilder: the content widget builder
  /// * itemBuilder: the item Builder
  /// * loadMoreBuilder: the load more builder
  /// * indicatorBg: the indicator background color of refresh
  /// * indicatorValue: the indicator value color of refresh
  /// * showLoadMore: the function to show load more
  /// * pullUpExtent: the pull-up extent as the delta away from maxScrollExtent
  /// * iosBuilder: ios refresh control indicator builder  for ios-style
  /// * refreshTriggerPullDistance: refresh trigger pull-distance for ios-style
  /// * refreshIndicatorExtent: refresh indicator extent for ios-style
  PullToRefreshState(
      ListHelper helper,
      WidgetBuilder empty,
      WidgetBuilder error,
      ContentWidgetBuilder contentBuilder,
      ItemBuilder itemBuilder,
      LoadMoreBuilder loadMoreBuilder,
      {Color indicatorBg,
      Color indicatorValue,
      ShowLoadMore showLoadMore,
      double pullUpExtent = 10,
      //ios
      RefreshControlIndicatorBuilder iosBuilder,
      double refreshTriggerPullDistance = 100,
      double refreshIndicatorExtent = 60}) {
    //wrap
    helper.uiCallback = new SimpleUiCallback(this, helper.uiCallback);
    this._helper = helper;
    _empty = empty;
    _error = error;
    _contentWidgetBuilder = contentBuilder;
    _loadMoreBuilder = loadMoreBuilder;
    _itemBuilder = itemBuilder;
    this._indicatorBg = indicatorBg ??= Colors.white70;
    this._indicatorValue = indicatorValue ??= Colors.pinkAccent;
    this._showLoadMore = showLoadMore ??= _showLoadMore0;
    this._pullUpExtent = pullUpExtent;
    if (_iosBuilder != null) {
      _refreshKeyIos = new GlobalKey<CupertinoSliverRefreshControlState>();
    } else {
      _refreshKey = new GlobalKey<RefreshIndicatorState>();
    }
    this.refreshIndicatorExtent = refreshIndicatorExtent;
    this.refreshTriggerPullDistance = refreshTriggerPullDistance;
  }

  /// update state
  void update(VoidCallback vc) {
    setState(vc);
  }

  /// show refresh
  void showRefresh() {
    setState(() {
      _showRefresh();
    });
  }

  void _showRefresh() {
    if (_iosBuilder != null) {
      _refreshKeyIos.currentState.show();
    } else {
      _refreshKey.currentState.show();
    }
  }

  @override
  void didUpdateWidget(StatefulWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - _pullUpExtent) {
        _getMoreData();
      }
    });
    //trigger refresh
    Future.delayed(new Duration(milliseconds: 30))
        .then((value) => _helper.refresh());
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (_showState) {
      case RefreshState.STATE_EMPTY:
        return _empty.call(context, _resetEmpty, () {
          _setShowState(RefreshState.STATE_NORMAL);
          _refresh();
        });

      case RefreshState.STATE_ERROR:
        return _error.call(context, _resetError, () {
          _setShowState(RefreshState.STATE_NORMAL);
          _refresh();
        });

      case RefreshState.STATE_NORMAL:
      default:
        IndexedWidgetBuilder indexBuilder = (context, index) {
          if (index > 0 && index == items.length) {
            return _loadMoreBuilder.call(
                context, _isPerformingRequest, _footerState);
          }
          return _itemBuilder.call(context, index, items[index]);
        };
        if (_iosBuilder != null) {
          Widget scrollView = CustomScrollView(
            controller: _scrollController,
            // If left unspecified, the [CustomScrollView] appends an
            // [AlwaysScrollableScrollPhysics]. Behind the scene, the ScrollableState
            // will attach that [AlwaysScrollableScrollPhysics] to the output of
            // [ScrollConfiguration.of] which will be a [ClampingScrollPhysics]
            // on Android.
            // To demonstrate the iOS behavior in this demo and to ensure that the list
            // always scrolls, we specifically use a [BouncingScrollPhysics] combined
            // with a [AlwaysScrollableScrollPhysics]
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: <Widget>[
              CupertinoSliverRefreshControl2(
                key: _refreshKeyIos,
                builder: _iosBuilder,
                refreshIndicatorExtent: this.refreshIndicatorExtent,
                refreshTriggerPullDistance: this.refreshTriggerPullDistance,
                onRefresh: () async {
                  _refresh();
                },
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((content, index) {
                  return indexBuilder.call(context, index);
                }, childCount: items.length > 0 ? items.length + 1 : 0),
              )
            ],
          );
          return _contentWidgetBuilder.call(context, scrollView, true);
        }
        RefreshIndicator indicator = RefreshIndicator(
          key: _refreshKey,
          onRefresh: () async {
            _refresh();
          },
          backgroundColor: _indicatorBg,
          color: _indicatorValue,
          child: ListView.builder(
            itemCount: items.length > 0 ? items.length + 1 : 0,
            itemBuilder: indexBuilder,
            controller: _scrollController,
            //resolve data so less cause can't refresh
            physics: AlwaysScrollableScrollPhysics(),
          ),
        );
        return _contentWidgetBuilder.call(context, indicator, false);
    }
  }

  void _refresh() {
    if (!_isPerformingRequest) {
      _helper.requestData(true);
    }
  }

  void _setShowState(RefreshState state) {
    setState(() {
      _showState = state;
    });
  }

  void _getMoreData() {
    if (_footerState != FooterState.STATE_THE_END && !_isPerformingRequest) {
      _showLoadMore.call(_scrollController);
      _helper.requestData(false, loadMore: true);
    }
  }

  void _showLoadMore0(ScrollController sc) {
    /*  print("showLoadMore: maxScroll = ${sc.position.maxScrollExtent}, "
        "minScroll = ${sc.position.minScrollExtent}"
        ", pixels = ${sc.position.pixels}");*/
    double edge = 50.0;
    //maxScrollExtent often is the content height of whole view, like ListView
    //pixels often is child offset
    double offsetFromBottom = sc.position.maxScrollExtent - sc.position.pixels;
    if (offsetFromBottom < edge) {
      //animate up
      sc.animateTo(sc.offset - (edge - offsetFromBottom),
          duration: new Duration(milliseconds: 500), curve: Curves.easeOut);
    }
  }
}
