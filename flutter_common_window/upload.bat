@REM git config --global http.proxy "http://127.0.0.1:1080"
@REM  git config --global --unset http.proxy
@REM flutter packages pub publish --dry-run
@REM 要连接accounts.google.com 必须挂代理。
set http_proxy=127.0.0.1:1081
set https_proxy=127.0.0.1:1081
flutter packages pub publish --server=https://pub.dartlang.org -v

@PAUSE