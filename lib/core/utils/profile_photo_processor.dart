import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as image;

/// Corrige a orientação, recorta o centro em formato quadrado e gera um JPEG
/// 512x512. Isso mantém o upload pequeno e a exibição consistente no app.
Future<Uint8List> prepareProfilePhoto(Uint8List bytes) =>
    compute(_prepareProfilePhoto, bytes);

Uint8List _prepareProfilePhoto(Uint8List bytes) {
  final decoded = image.decodeImage(bytes);
  if (decoded == null) throw const FormatException('Imagem inválida.');

  final oriented = image.bakeOrientation(decoded);
  final side = oriented.width < oriented.height
      ? oriented.width
      : oriented.height;
  final cropped = image.copyCrop(
    oriented,
    x: (oriented.width - side) ~/ 2,
    y: (oriented.height - side) ~/ 2,
    width: side,
    height: side,
  );
  final resized = image.copyResize(
    cropped,
    width: 512,
    height: 512,
    interpolation: image.Interpolation.average,
  );
  return Uint8List.fromList(image.encodeJpg(resized, quality: 85));
}
