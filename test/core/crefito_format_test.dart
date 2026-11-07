import 'package:agendaifisiomobile/core/utils/input_masks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('monta o CREFITO a partir da região e do número', () {
    expect(InputMasks.buildCrefito('3', '123456'), 'CREFITO-3/123456-F');
    expect(InputMasks.buildCrefito('03', '123456'), 'CREFITO-3/123456-F');
    expect(InputMasks.buildCrefito('12', '1234'), 'CREFITO-12/1234-F');
  });

  test('separa um CREFITO salvo em região e número', () {
    final crefito = InputMasks.parseCrefito('CREFITO-3/100301-F');
    expect(crefito?.region, '3');
    expect(crefito?.number, '100301');
    expect(InputMasks.parseCrefito('123123123'), isNull);
  });

  test('aceita só o formato completo com categoria F', () {
    expect(InputMasks.isCrefito('CREFITO-3/100301-F'), isTrue);
    expect(InputMasks.isCrefito('CREFITO-12/123-F'), isTrue);
    expect(InputMasks.isCrefito('CREFITO-3/123456'), isFalse);
    expect(InputMasks.isCrefito('CREFITO-3/123456-TO'), isFalse);
  });

  test('o -F fica colado ao número e o apagar funciona', () {
    final formatter = InputMasks.crefitoNumberFormatter();
    TextEditingValue type(String old, String next) =>
        formatter.formatEditUpdate(
          TextEditingValue(text: old),
          TextEditingValue(text: next),
        );
    expect(type('', '1').text, '1-F');
    expect(type('12-F', '123-F').text, '123-F');
    expect(type('123-F', '123-').text, '12-F');
    expect(type('1-F', '1-').text, '-F');
    expect(type('-F', '-').text, '-F');
    expect(type('-F', '-F').selection.baseOffset, 0);
    expect(type('123456-F', '1234567-F').text, '123456-F');
  });

  test('a região não aceita zero à esquerda', () {
    final formatter = InputMasks.crefitoRegionFormatter();
    String type(String text) => formatter
        .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: text))
        .text;
    expect(type('0'), '');
    expect(type('09'), '9');
    expect(type('10'), '10');
    expect(type('123'), '12');
  });
}
