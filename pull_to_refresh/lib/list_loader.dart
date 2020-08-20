typedef OnResult = void Function(
    Object context, Map<String, dynamic> params, bool refresh, dynamic data);
typedef OnException = void Function(
    Object context, Map<String, dynamic> params, bool refresh, Exception e);
typedef ParameterInterceptor = Map Function(Map);
typedef Repository = void Function(
    Object context, Map<String, dynamic> params, bool refresh, OnResult result,
    {OnException e});

/// the page manager.
class PageManager {
  /// the page no/index.
  int pageNo = 0;
  /// the page size.
  int pageSize = 10;
  /// indicate the all data load done or not
  bool allLoadDone;

  /// the repository which actually load data
  final Repository _repository;
  /// the parameter interceptor. which can help to to add extra request parameters.
  final ParameterInterceptor _interceptor;

  /// create page manager by repository and interceptor
  /// * _repository: the repository which used to load data
  /// * _interceptor: the parameter interceptor
  PageManager(this._repository, this._interceptor);

  /// do request data
  /// * context: the context
  /// * refresh: true if do this as refresh
  /// * result: the normal callback of response
  /// * e: the exception callback
  void request(Object context, bool refresh, OnResult result, OnException e) {
    Map<String, dynamic> map = _getParameterMap(refresh);
    _repository.call(context, map, refresh, result, e: e);
  }

  Map<String, dynamic> _getParameterMap(bool refresh) {
    if (refresh) {
      pageNo = 1;
      allLoadDone = false;
    } else {
      pageNo += 1;
    }
    Map<String, dynamic> map = createMap(pageNo, pageSize);
    if (_interceptor != null) {
      map = _interceptor.call(map);
    }
    return map;
  }
  /// create parameter map by pageNo and pageSize.
  Map<String, dynamic> createMap(int pageNo, int pageSize) {
    return {"pageNo": pageNo, "pageSize": pageSize};
  }
}

/// the network request context, like http/https
class NetworkRequestContext {
  static const int TYPE_GET = 1;
  static const int TYPE_POST_BODY = 2;
  static const int TYPE_POST_FORM = 3;

  final String url;
  final int type;
  final Object dataType;

  NetworkRequestContext(this.url, this.type, this.dataType);
}

/// the list data owner
abstract class ListDataOwner {
  List getList();
}
/// the list callback
class ListCallback {
  /// handled refresh or not.
  bool handleRefresh() {
    return false;
  }
  /// convert list data to another.
  List map(List data) {
    return data;
  }
  /// get base list data. after call this often call [map]
  List getListData(Object data) {
    if (data is List) {
      return data;
    }
    if (data is ListDataOwner) {
      return data.getList();
    }
    throw new Exception("data should impl ListDataOwner");
  }
}

/// the ui callback
abstract class UiCallback {
  ///set requesting state.
  ///* requesting: indicate is requesting or not
  ///* clearItems: true if clear items
  ///* resetError: true if reset error
  ///* resetEmpty: true if reset empty
  ///* loadMore: true if is loading more. see [FooterState.STATE_LOADING].
  void setRequesting(bool requesting,
      {bool clearItems, bool resetError, bool resetEmpty, bool loadMore});

  /// mark is refreshing
  void markRefreshing();

  /// show empty. indicate requesting = false. refreshing = false
  void showEmpty(dynamic data);

  /// show list content. indicate requesting = false. refreshing = false
  void showContent(List data, FooterState state);

  /// show error content. indicate requesting = false. refreshing = false
  void showError(Exception e, bool clearItems);
}

/// the footer state of load more
enum FooterState {
  /// normal state
  STATE_NORMAL,

  /// loading all data done.
  STATE_THE_END,

  /// loading
  STATE_LOADING,

  /// loading error by network. current not used.
  STATE_NET_ERROR
}

class ListHelper {
  /// the list callback, which help you convert data to list.
  ListCallback callback;

  /// the ui callback of pull-to-refresh
  UiCallback uiCallback;

  /// the page manager which help to manage page.
  PageManager pageManager;

  /// the context of load list data. for http/https. you can use [NetworkRequestContext].
  Object context;

  /// do request data.
  /// * refresh: true if as refresh
  /// * loadMore: true if is load more
  void requestData(bool refresh, {bool loadMore}) {
    uiCallback.setRequesting(true,
        clearItems: refresh,
        resetEmpty: true,
        resetError: true,
        loadMore: loadMore);

    pageManager.request(context, refresh, _onResult, _onException);
  }

  /// refresh data
  void refresh() {
    if (!callback.handleRefresh()) {
      uiCallback.markRefreshing();
      requestData(true);
    }
  }

  void _onResult(
      Object context, Map<String, dynamic> params, bool refresh, dynamic data) {
    List realData = callback.getListData(data);
    if (realData.isEmpty && pageManager.pageNo == 1) {
      uiCallback.showEmpty(data);
      return;
    }
    FooterState state;
    if (realData.length < pageManager.pageSize) {
      pageManager.allLoadDone = true;
      state = pageManager.pageNo == 1
          ? FooterState.STATE_NORMAL
          : FooterState.STATE_THE_END;
    } else {
      state = FooterState.STATE_NORMAL;
    }
    uiCallback.showContent(callback.map(realData), state);
  }

  void _onException(
      Object context, Map<String, dynamic> params, bool refresh, Exception e) {
    //
    uiCallback.showError(e, true);
  }
}
