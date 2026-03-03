import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'dni_capture.dart';

Future<CapturedDniImage?> captureDniImageImpl() async {
  final completer = Completer<CapturedDniImage?>();

  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..setAttribute('capture', 'environment')
    ..style.position = 'fixed'
    ..style.left = '-9999px'
    ..style.top = '0'
    ..style.opacity = '0'
    ..style.pointerEvents = 'none';

  void cleanup() {
    input.remove();
  }

  void completeOnce(CapturedDniImage? image) {
    if (!completer.isCompleted) {
      completer.complete(image);
    }
    cleanup();
  }

  void completeErrorOnce(Object error) {
    if (!completer.isCompleted) {
      completer.completeError(error);
    }
    cleanup();
  }

  input.onChange.first.then((_) {
    final file = input.files?.first;
    if (file == null) {
      completeOnce(null);
      return;
    }

    final reader = html.FileReader();
    reader.onError.first.then((_) {
      completeErrorOnce(StateError('No se pudo leer la imagen del DNI.'));
    });

    reader.onLoadEnd.first.then((_) {
      final result = reader.result;
      if (result is ByteBuffer) {
        completeOnce(
          CapturedDniImage(
            bytes: Uint8List.view(result),
            filename: file.name.isEmpty ? 'dni.jpg' : file.name,
            mimeType: file.type.isEmpty ? 'image/jpeg' : file.type,
          ),
        );
        return;
      }
      if (result is Uint8List) {
        completeOnce(
          CapturedDniImage(
            bytes: result,
            filename: file.name.isEmpty ? 'dni.jpg' : file.name,
            mimeType: file.type.isEmpty ? 'image/jpeg' : file.type,
          ),
        );
        return;
      }
      if (result is List<int>) {
        completeOnce(
          CapturedDniImage(
            bytes: result,
            filename: file.name.isEmpty ? 'dni.jpg' : file.name,
            mimeType: file.type.isEmpty ? 'image/jpeg' : file.type,
          ),
        );
        return;
      }

      completeErrorOnce(StateError('Formato de imagen inválido.'));
    });

    reader.readAsArrayBuffer(file);
  });

  html.document.body?.append(input);
  input.value = '';
  input.click();

  return completer.future.timeout(
    const Duration(seconds: 45),
    onTimeout: () {
      cleanup();
      return null;
    },
  );
}
