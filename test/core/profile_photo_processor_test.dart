import 'dart:typed_data';

import 'package:agendaifisiomobile/core/utils/profile_photo_processor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

void main() {
  test('foto de perfil é recortada e comprimida em JPEG 512x512', () async {
    final original = image.Image(width: 900, height: 600)
      ..clear(image.ColorRgb8(15, 118, 110));

    final result = await prepareProfilePhoto(
      Uint8List.fromList(image.encodePng(original)),
    );
    final decoded = image.decodeJpg(result);

    expect(decoded, isNotNull);
    expect(decoded!.width, 512);
    expect(decoded.height, 512);
    expect(result.length, lessThan(5 * 1024 * 1024));
  });

  test('arquivo inválido é rejeitado antes do upload', () async {
    await expectLater(
      prepareProfilePhoto(Uint8List.fromList([1, 2, 3])),
      throwsA(isA<FormatException>()),
    );
  });
}
