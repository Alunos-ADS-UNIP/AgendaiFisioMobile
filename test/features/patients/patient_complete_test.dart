import 'package:agendaifisiomobile/features/patients/domain/patient.dart';
import 'package:flutter_test/flutter_test.dart';

Patient _patient({
  String nome = 'Renan Santos',
  String cpf = '123.456.789-09',
  DateTime? nascimento,
  String telefone = '11987654321',
  String cidade = 'Cuiaba',
}) => Patient(
  nomeCompleto: nome,
  cpf: cpf,
  telefone: telefone,
  dataNascimento: nascimento ?? DateTime(1990, 1, 1),
  sexo: '',
  estadoCivil: '',
  email: 'renan@teste.com',
  endereco: PatientAddress(
    rua: 'Rua A',
    numero: '10',
    cep: '78000000',
    bairro: 'Centro',
    cidade: cidade,
    estado: 'MT',
  ),
);

void main() {
  test('cadastro completo libera o aplicativo', () {
    expect(_patient().isComplete, isTrue);
  });

  test('nome pendente bloqueia', () {
    expect(_patient(nome: 'Cadastro Pendente').isComplete, isFalse);
  });

  test('CPF incompleto ou sem data bloqueia', () {
    expect(_patient(cpf: '123').isComplete, isFalse);
    expect(_patient(nascimento: DateTime(1800)).isComplete, isFalse);
  });

  test('endereço sem cidade bloqueia', () {
    expect(_patient(cidade: '').isComplete, isFalse);
  });
}
