git config --global http.proxy "http://127.0.0.1:1080"
flutter packages pub publish
git config --global --unset http.proxy
@PAUSE