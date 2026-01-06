import 'dart:html' as html;

void updateFavicon(String? basePath) {
  if (basePath == null || basePath.isEmpty) {
    return;
  }

  final document = html.document;
  _upsertLink(
    document,
    selector: 'link[rel="icon"][sizes="16x16"]',
    rel: 'icon',
    sizes: '16x16',
    type: 'image/png',
    href: '$basePath/favicon-16x16.png',
  );
  _upsertLink(
    document,
    selector: 'link[rel="icon"][sizes="32x32"]',
    rel: 'icon',
    sizes: '32x32',
    type: 'image/png',
    href: '$basePath/favicon-32x32.png',
  );
  _upsertLink(
    document,
    selector: 'link[rel="icon"][sizes="48x48"]',
    rel: 'icon',
    sizes: '48x48',
    type: 'image/png',
    href: '$basePath/favicon-48x48.png',
  );
  _upsertLink(
    document,
    selector: 'link[rel="shortcut icon"]',
    rel: 'shortcut icon',
    href: '$basePath/favicon.ico',
  );
  _upsertLink(
    document,
    selector: 'link[rel="apple-touch-icon"][sizes="180x180"]',
    rel: 'apple-touch-icon',
    sizes: '180x180',
    href: '$basePath/apple-touch-icon.png',
  );
  _upsertLink(
    document,
    selector: 'link[rel="manifest"]',
    rel: 'manifest',
    href: '$basePath/site.webmanifest',
  );
}

void _upsertLink(
  html.Document document, {
  required String selector,
  required String rel,
  String? sizes,
  String? type,
  required String href,
}) {
  final existing = document.querySelector(selector) as html.LinkElement?;
  final link = existing ?? html.LinkElement();
  link.rel = rel;
  if (type != null) {
    link.type = type;
  }
  if (sizes != null) {
    link.setAttribute('sizes', sizes);
  }
  link.href = href;
  if (link.parent == null) {
    final head = document.querySelector('head');
    head?.append(link);
  }
}
