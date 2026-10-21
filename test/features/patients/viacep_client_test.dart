import 'dart:async';
import 'dart:convert';

import 'package:agendaifisiomobile/features/patients/data/viacep_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// Resposta real do ViaCEP para 01001-000.
const _sePayload = {
  'cep': '01001-000',
  'logradouro': 'Praça da Sé',
  'complemento': 'lado ímpar',
  'bairro': 'Sé',
  'localidade': 'São Paulo',
  'uf': 'SP',
  'ibge': '3550308',
};

http.Response _jsonResponse(Object body, [int status = 200]) =>
    http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Matcher _failsWith(CepLookupFailure failure) => throwsA(
  isA<CepLookupException>().having((e) => e.failure, 'failure', failure),
);

void main() {
  test('converte a resposta do ViaCEP e consulta a URL correta', () async {
    late Uri requested;
    final client = ViaCepClient(
      httpClient: MockClient((request) async {
        requested = request.url;
        return _jsonResponse(_sePayload);
      }),
    );

    final address = await client.lookup('01001-000');

    expect(requested.toString(), 'https://viacep.com.br/ws/01001000/json/');
    expect(address.rua, 'Praça da Sé');
    expect(address.bairro, 'Sé');
    expect(address.cidade, 'São Paulo');
    expect(address.estado, 'SP');
  });

  test('campos ausentes viram string vazia (CEP geral de cidade)', () async {
    final client = ViaCepClient(
      httpClient: MockClient(
        (_) async => _jsonResponse({
          'cep': '12940-000',
          'logradouro': '',
          'bairro': '',
          'localidade': 'Atibaia',
          'uf': 'SP',
        }),
      ),
    );

    final address = await client.lookup('12940000');

    expect(address.rua, isEmpty);
    expect(address.bairro, isEmpty);
    expect(address.cidade, 'Atibaia');
    expect(address.estado, 'SP');
  });

  test('CEP com menos de 8 dígitos falha sem chamar a rede', () async {
    var calls = 0;
    final client = ViaCepClient(
      httpClient: MockClient((_) async {
        calls++;
        return _jsonResponse(_sePayload);
      }),
    );

    await expectLater(
      client.lookup('0100100'),
      _failsWith(CepLookupFailure.invalid),
    );
    expect(calls, 0);
  });

  test('{"erro": true} significa CEP inexistente', () async {
    final client = ViaCepClient(
      httpClient: MockClient((_) async => _jsonResponse({'erro': true})),
    );

    await expectLater(
      client.lookup('99999999'),
      _failsWith(CepLookupFailure.notFound),
    );
  });

  test('{"erro": "true"} (formato antigo) também é CEP inexistente', () async {
    final client = ViaCepClient(
      httpClient: MockClient((_) async => _jsonResponse({'erro': 'true'})),
    );

    await expectLater(
      client.lookup('99999999'),
      _failsWith(CepLookupFailure.notFound),
    );
  });

  test('HTTP 400 vira CEP inválido', () async {
    final client = ViaCepClient(
      httpClient: MockClient((_) async => http.Response('Bad Request', 400)),
    );

    await expectLater(
      client.lookup('01001000'),
      _failsWith(CepLookupFailure.invalid),
    );
  });

  test('HTTP 500 vira falha de rede', () async {
    final client = ViaCepClient(
      httpClient: MockClient((_) async => http.Response('erro', 500)),
    );

    await expectLater(
      client.lookup('01001000'),
      _failsWith(CepLookupFailure.network),
    );
  });

  test('corpo que não é JSON vira falha de rede', () async {
    final client = ViaCepClient(
      httpClient: MockClient(
        (_) async => http.Response('<html>oops</html>', 200),
      ),
    );

    await expectLater(
      client.lookup('01001000'),
      _failsWith(CepLookupFailure.network),
    );
  });

  test('exceção do cliente HTTP vira falha de rede', () async {
    final client = ViaCepClient(
      httpClient: MockClient(
        (_) async => throw http.ClientException('sem conexão'),
      ),
    );

    await expectLater(
      client.lookup('01001000'),
      _failsWith(CepLookupFailure.network),
    );
  });

  test('sem resposta dentro do limite vira timeout', () async {
    final never = Completer<http.Response>();
    final client = ViaCepClient(
      httpClient: MockClient((_) => never.future),
      timeout: const Duration(milliseconds: 20),
    );

    await expectLater(
      client.lookup('01001000'),
      _failsWith(CepLookupFailure.timeout),
    );
  });
}
