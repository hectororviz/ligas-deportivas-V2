import 'dart:html' as html;

void updateFavicon(String? url) {
  if (url == null || url.isEmpty) {
    return;
  }

  final document = html.document;
  final existing = document.querySelector("link[rel~='icon']") as html.LinkElement?;
  final link = existing ?? html.LinkElement()..rel = 'icon';
  link.href = url;
  if (link.parent == null) {
    document.head?.append(link);
  }
}
