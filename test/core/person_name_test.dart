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

  group('shortPersonName', () {
    test('mantém só o primeiro e o último nome', () {
      expect(shortPersonName('Márcio Cardoso Santos'), 'Márcio Santos');
      expect(shortPersonName('Ana Paula de Souza Lima'), 'Ana Lima');
    });

    test('trata nome simples, espaços e valores vazios', () {
      expect(shortPersonName('João'), 'João');
      expect(shortPersonName('  Márcio   Santos  '), 'Márcio Santos');
      expect(shortPersonName(null), '');
      expect(shortPersonName('   '), '');
    });
  });
}
