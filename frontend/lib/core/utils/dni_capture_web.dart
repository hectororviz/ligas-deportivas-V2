import 'dart:async';
import 'dart:html' as html;

import 'dni_capture.dart';

Future<CapturedDniImage?> captureDniImageImpl() async {
  final completer = Completer<CapturedDniImage?>();
  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..setAttribute('capture', 'environment');

  input.onChange.first.then((_) {
    final file = input.files?.first;
    if (file == null) {
      completer.complete(null);
      return;
    }

    final reader = html.FileReader();
    reader.onError.first.then((_) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('No se pudo leer la imagen del DNI.'));
      }
    });

    reader.onLoadEnd.first.then((_) {
      final result = reader.result;
      if (result is! List<int>) {
        completer.completeError(StateError('Formato de imagen inválido.'));
        return;
      }

      completer.complete(
        CapturedDniImage(
          bytes: result,
          filename: file.name.isEmpty ? 'dni.jpg' : file.name,
          mimeType: file.type.isEmpty ? 'image/jpeg' : file.type,
        ),
      );
    });

    reader.readAsArrayBuffer(file);
  });

  input.click();
  return completer.future;
}
