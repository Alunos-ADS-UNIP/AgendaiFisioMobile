import 'package:agendaifisiomobile/core/utils/date_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('monta dia da semana, dia, mês abreviado e ano', () {
    expect(
      weekdayShortMonthDate(DateTime(2026, 10, 29)),
      'quinta-feira, 29 de out. de 2026',
    );
  });

  test('usa o nome certo para domingo e janeiro', () {
    expect(
      weekdayShortMonthDate(DateTime(2026, 1, 4)),
      'domingo, 4 de jan. de 2026',
    );
  });
}
