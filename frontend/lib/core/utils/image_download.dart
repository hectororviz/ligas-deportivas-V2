import 'image_download_stub.dart' if (dart.library.html) 'image_download_web.dart';

Future<void> downloadImage({
  required List<int> bytes,
  required String filename,
  String mimeType = 'image/png',
}) {
  return downloadImageImpl(bytes: bytes, filename: filename, mimeType: mimeType);
}
