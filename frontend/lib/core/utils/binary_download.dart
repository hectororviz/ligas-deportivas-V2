import 'dart:typed_data';

import 'binary_download_stub.dart' if (dart.library.html) 'binary_download_web.dart';

Future<void> downloadBinary({
  required Uint8List bytes,
  required String filename,
  required String mimeType,
}) {
  return downloadBinaryImpl(bytes: bytes, filename: filename, mimeType: mimeType);
}
