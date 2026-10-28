import 'package:agendaifisiomobile/core/utils/input_masks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formata a digitação no padrão 12345-F', () {
    expect(InputMasks.formatCrefito('12345'), '12345');
    expect(InputMasks.formatCrefito('12345f'), '12345-F');
    expect(InputMasks.formatCrefito('12345-f'), '12345-F');
    expect(InputMasks.formatCrefito('1234567A'), '123456-A');
    expect(InputMasks.formatCrefito('F'), '');
  });

  test('aceita só o formato convencional', () {
    expect(InputMasks.isCrefito('12345-F'), isTrue);
    expect(InputMasks.isCrefito('123-a'), isTrue);
    expect(InputMasks.isCrefito('12-F'), isFalse);
    expect(InputMasks.isCrefito('12345F'), isFalse);
    expect(InputMasks.isCrefito('CREFITO-1'), isFalse);
  });

  test('exibe valores salvos no padrão, mantendo os antigos', () {
    expect(InputMasks.displayCrefito('12345F'), '12345-F');
    expect(InputMasks.displayCrefito('12345-f'), '12345-F');
    expect(InputMasks.displayCrefito('CREFITO-1'), 'CREFITO-1');
  });
}
