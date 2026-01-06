import 'favicon_manager_stub.dart'
    if (dart.library.html) 'favicon_manager_web.dart';

class FaviconManager {
  static void update(String? url) {
    updateFavicon(url);
  }
}
