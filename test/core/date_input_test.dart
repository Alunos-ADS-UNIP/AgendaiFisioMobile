import 'package:agendaifisiomobile/core/utils/input_masks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('converte DD/MM/AAAA em data', () {
    expect(InputMasks.parseDate('01/01/1990'), DateTime(1990, 1, 1));
    expect(InputMasks.parseDate('29/02/2000'), DateTime(2000, 2, 29));
  });

  test('rejeita data incompleta ou inexistente', () {
    expect(InputMasks.parseDate(''), isNull);
    expect(InputMasks.parseDate('01/01/19'), isNull);
    expect(InputMasks.parseDate('31/02/1990'), isNull);
    expect(InputMasks.parseDate('29/02/1999'), isNull);
    expect(InputMasks.parseDate('1990-01-01'), isNull);
  });

  test('a máscara monta DD/MM/AAAA enquanto o usuário digita', () {
    final formatter = InputMasks.dataFormatter();
    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '01011990'),
    );
    expect(result.text, '01/01/1990');
  });
}
