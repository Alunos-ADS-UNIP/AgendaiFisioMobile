import 'dart:convert';

import 'package:agendaifisiomobile/features/appointments/data/appointment_api_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

AppointmentApiRepository _repo(Map<String, dynamic> profile) =>
    AppointmentApiRepository(
      baseUri: Uri.parse('https://api.test'),
      tokenProvider: () async => 'token',
      client: MockClient(
        (request) async => http.Response(jsonEncode(profile), 200),
      ),
    );

Map<String, dynamic> _completeProfile() => {
  'nomeCompleto': 'Renan Santos',
  'cpf': '123.456.789-09',
  'telefone': '(11) 98765-4321',
  'dataNascimento': '1990-01-01T00:00:00',
  'sexo': 'M',
  'estadoCivil': 'Solteiro',
  'email': 'renan@teste.com',
  'endereco': {
    'rua': 'Rua A',
    'numero': '10',
    'complemento': '',
    'cep': '01001-000',
    'bairro': 'Centro',
    'cidade': 'São Paulo',
    'estado': 'SP',
  },
};

void main() {
  test('cadastro completo não tem campos faltando', () async {
    expect(await _repo(_completeProfile()).missingPatientProfileFields(), isEmpty);
  });

  test('cadastro pendente aponta o nome como faltante', () async {
    final profile = _completeProfile()..['nomeCompleto'] = 'Cadastro Pendente';
    expect(
      await _repo(profile).missingPatientProfileFields(),
      ['nome completo'],
    );
  });

  test('endereço sem cidade aponta a cidade como faltante', () async {
    final profile = _completeProfile();
    (profile['endereco'] as Map<String, dynamic>)['cidade'] = '';
    expect(await _repo(profile).missingPatientProfileFields(), ['cidade']);
  });
}
