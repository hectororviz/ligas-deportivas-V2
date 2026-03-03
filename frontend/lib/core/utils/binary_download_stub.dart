import 'dart:typed_data';

Future<void> downloadBinaryImpl({
  required Uint8List bytes,
  required String filename,
  required String mimeType,
}) async {
  throw UnsupportedError('Descarga de archivos disponible solo en Web.');
}
