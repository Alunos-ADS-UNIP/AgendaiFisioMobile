import 'package:agendaifisiomobile/core/utils/person_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mantém só o primeiro e o último nome', () {
    expect(shortPersonName('Márcio Cardoso Santos'), 'Márcio Santos');
    expect(shortPersonName('Ana Paula de Souza Lima'), 'Ana Lima');
  });

  test('nome com dois termos ou um termo fica igual', () {
    expect(shortPersonName('Renan Santos'), 'Renan Santos');
    expect(shortPersonName('Marina'), 'Marina');
  });

  test('ignora espaços extras e vazios', () {
    expect(shortPersonName('  Márcio   Santos  '), 'Márcio Santos');
    expect(shortPersonName(null), '');
    expect(shortPersonName('   '), '');
  });
}
