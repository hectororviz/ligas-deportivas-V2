import 'dni_capture_stub.dart' if (dart.library.html) 'dni_capture_web.dart';

class CapturedDniImage {
  CapturedDniImage({
    required this.bytes,
    required this.filename,
    required this.mimeType,
  });

  final List<int> bytes;
  final String filename;
  final String mimeType;
}

Future<CapturedDniImage?> captureDniImage() => captureDniImageImpl();
