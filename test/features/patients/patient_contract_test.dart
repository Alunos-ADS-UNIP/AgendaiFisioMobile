import 'dart:convert';

import 'package:agendaifisiomobile/core/network/api_client.dart';
import 'package:agendaifisiomobile/features/patients/data/dtos/patient_dtos.dart';
import 'package:agendaifisiomobile/features/patients/data/patient_api.dart';
import 'package:agendaifisiomobile/features/patients/domain/patient.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Backend falso que reproduz o contrato do PacienteUpdateDTO descrito no
/// review do PR #1:
///
/// - PUT /api/paciente/completar-perfil lê `rua`, `numero`, `complemento`,
///   `cep`, `bairro`, `cidade` e `estado` **na raiz** do JSON. Chaves
///   desconhecidas (como um `endereco` aninhado) são ignoradas em silêncio e
///   o PUT responde 200 — exatamente o comportamento que escondeu o bug.
/// - GET /api/paciente/me devolve o endereço aninhado em `endereco`.
///
/// Se o backend mudar o DTO, atualize este fake junto (ou troque por um
/// teste de integração contra a API em Docker).
class _FakePacienteBackend {
  Map<String, String> _stored = {};
  Map<String, dynamic>? lastPutBody;

  String _read(Map<String, dynamic> body, String key) =>
      body[key]?.toString() ?? '';

  Future<http.Response> handle(http.Request request) async {
    if (request.method == 'PUT' &&
        request.url.path == '/api/paciente/completar-perfil') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      lastPutBody = body;
      _stored = {
        for (final key in const [
          'nomeCompleto',
          'cpf',
          'telefone',
          'dataNascimento',
          'sexo',
          'estadoCivil',
          'rua',
          'numero',
          'complemento',
          'cep',
          'bairro',
          'cidade',
          'estado',
        ])
          key: _read(body, key),
      };
      return _json({'mensagem': 'Perfil atualizado com sucesso!'});
    }

    if (request.method == 'GET' && request.url.path == '/api/paciente/me') {
      return _json({
        'id': 'p-1',
        'usuarioId': 'u-1',
        'email': 'paciente@exemplo.com',
        'nomeCompleto': _stored['nomeCompleto'] ?? 'Cadastro Pendente',
        'cpf': _stored['cpf'] ?? '',
        'telefone': _stored['telefone'] ?? '',
        'dataNascimento': _stored['dataNascimento'] ?? '0001-01-01T00:00:00',
        'sexo': _stored['sexo'] ?? '',
        'estadoCivil': _stored['estadoCivil'] ?? '',
        'endereco': {
          'rua': _stored['rua'] ?? '',
          'numero': _stored['numero'] ?? '',
          'complemento': _stored['complemento'] ?? '',
          'cep': _stored['cep'] ?? '',
          'bairro': _stored['bairro'] ?? '',
          'cidade': _stored['cidade'] ?? '',
          'estado': _stored['estado'] ?? '',
        },
      });
    }

    return http.Response('Not Found', 404);
  }

  http.Response _json(Object body) => http.Response(
    jsonEncode(body),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

PatientUpdateRequest _fullRequest() => PatientUpdateRequest(
  nomeCompleto: 'Mariana Oliveira',
  cpf: '12345678901',
  telefone: '11987654321',
  dataNascimento: DateTime(1992, 5, 18),
  sexo: 'Feminino',
  estadoCivil: 'Solteiro(a)',
  endereco: const PatientAddress(
    rua: 'Praça da Sé',
    numero: '100',
    complemento: 'Apto 12',
    cep: '01001000',
    bairro: 'Sé',
    cidade: 'São Paulo',
    estado: 'SP',
  ),
);

void main() {
  group('PatientUpdateRequest.toJson', () {
    test('envia os campos de endereço na raiz, sem objeto aninhado', () {
      final json = _fullRequest().toJson();

      expect(json.containsKey('endereco'), isFalse);
      expect(json['rua'], 'Praça da Sé');
      expect(json['numero'], '100');
      expect(json['complemento'], 'Apto 12');
      expect(json['cep'], '01001000');
      expect(json['bairro'], 'Sé');
      expect(json['cidade'], 'São Paulo');
      expect(json['estado'], 'SP');
    });

    test('formata a data de nascimento como yyyy-MM-dd', () {
      expect(_fullRequest().toJson()['dataNascimento'], '1992-05-18');
    });
  });

  group('contrato PUT completar-perfil → GET me', () {
    late _FakePacienteBackend backend;
    late PatientApi api;

    setUp(() {
      backend = _FakePacienteBackend();
      api = PatientApi(
        ApiClient(
          baseUrl: 'http://backend.test',
          httpClient: MockClient(backend.handle),
          authHeaderProvider: () async => 'token-de-teste',
        ),
      );
    });

    test('persiste todos os campos, inclusive o endereço', () async {
      await api.completarPerfil(_fullRequest());
      final profile = (await api.getMe()).toDomain();

      expect(profile.nomeCompleto, 'Mariana Oliveira');
      expect(profile.cpf, '12345678901');
      expect(profile.telefone, '11987654321');
      expect(profile.dataNascimento, DateTime(1992, 5, 18));
      expect(profile.sexo, 'Feminino');
      expect(profile.estadoCivil, 'Solteiro(a)');
      expect(profile.endereco.rua, 'Praça da Sé');
      expect(profile.endereco.numero, '100');
      expect(profile.endereco.complemento, 'Apto 12');
      expect(profile.endereco.cep, '01001000');
      expect(profile.endereco.bairro, 'Sé');
      expect(profile.endereco.cidade, 'São Paulo');
      expect(profile.endereco.estado, 'SP');
      expect(profile.isPendingCompletion, isFalse);
    });

    test('perfil novo vem como pendente e sem data de nascimento', () async {
      final profile = (await api.getMe()).toDomain();

      expect(profile.isPendingCompletion, isTrue);
      expect(profile.dataNascimento, isNull);
      expect(profile.endereco.isEmpty, isTrue);
    });

    test('o corpo enviado ao backend não contém "endereco"', () async {
      await api.completarPerfil(_fullRequest());

      expect(backend.lastPutBody, isNotNull);
      expect(backend.lastPutBody!.containsKey('endereco'), isFalse);
    });
  });
}
