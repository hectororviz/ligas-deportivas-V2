import 'csv_download_stub.dart' if (dart.library.html) 'csv_download_web.dart';

Future<void> downloadCsv({required String content, required String filename}) {
  return downloadCsvImpl(content: content, filename: filename);
}
