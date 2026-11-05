import 'package:agendaifisiomobile/core/utils/person_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('firstName', () {
    test('devolve só o primeiro nome', () {
      expect(firstName('Maria Souza Lima'), 'Maria');
    });

    test('capitaliza a primeira letra', () {
      expect(firstName('joão da silva'), 'João');
    });

    test('ignora espaços extras', () {
      expect(firstName('  Ana   Paula '), 'Ana');
    });

    test('nome de uma palavra só', () {
      expect(firstName('Luis'), 'Luis');
    });

    test('vazio, nulo e placeholder do backend viram string vazia', () {
      expect(firstName(null), '');
      expect(firstName('   '), '');
      expect(firstName('Cadastro Pendente'), '');
    });
  });
}
