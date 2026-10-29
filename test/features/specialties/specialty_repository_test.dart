import 'package:flutter_test/flutter_test.dart';

import 'package:agendaifisiomobile/features/specialties/data/specialty_api_client.dart';
import 'package:agendaifisiomobile/features/specialties/data/specialty_api_repository.dart';
import 'package:agendaifisiomobile/features/specialties/domain/specialty_failure.dart';

class FakeSpecialtyHttpClient implements SpecialtyHttpClient {
  FakeSpecialtyHttpClient({
    this.getResponse,
    this.postResponse,
    this.putResponse,
  });

  SpecialtyHttpResponse? getResponse;
  SpecialtyHttpResponse? postResponse;
  SpecialtyHttpResponse? putResponse;
  String? lastPath;
  Map<String, dynamic>? lastBody;
  bool? lastAuthenticated;

  @override
  Future<SpecialtyHttpResponse> get(
    String path, {
    required bool authenticated,
  }) async {
    lastPath = path;
    lastAuthenticated = authenticated;
    return getResponse!;
  }

  @override
  Future<SpecialtyHttpResponse> post(
    String path,
    Map<String, dynamic> body, {
    required bool authenticated,
  }) async {
    lastPath = path;
    lastBody = body;
    lastAuthenticated = authenticated;
    return postResponse!;
  }

  @override
  Future<SpecialtyHttpResponse> put(
    String path,
    Map<String, dynamic> body, {
    required bool authenticated,
  }) async {
    lastPath = path;
    lastBody = body;
    lastAuthenticated = authenticated;
    return putResponse!;
  }
}

void main() {
  test(
    'lista publicamente e remove duplicidade por ID e nome normalizado',
    () async {
      final client = FakeSpecialtyHttpClient(
        getResponse: const SpecialtyHttpResponse(
          statusCode: 200,
          body: [
            {'id': '1', 'nome': 'Aquática'},
            {'id': '1', 'nome': 'Aquática'},
            {'id': '2', 'nome': '  AQUATICA  '},
            {'id': '3', 'nome': 'Ortopedia'},
          ],
        ),
      );
      final repository = SpecialtyApiRepository(client);

      final result = await repository.list();

      expect(client.lastPath, '/api/especialidade');
      expect(client.lastAuthenticated, isFalse);
      expect(result.map((item) => item.id), ['1', '3']);
    },
  );

  test('consulta especialidade por ID com URL codificada', () async {
    final client = FakeSpecialtyHttpClient(
      getResponse: const SpecialtyHttpResponse(
        statusCode: 200,
        body: {'id': 'abc/123', 'nome': 'Osteopatia'},
      ),
    );

    final result = await SpecialtyApiRepository(client).getById('abc/123');

    expect(client.lastPath, '/api/especialidade/abc%2F123');
    expect(client.lastAuthenticated, isFalse);
    expect(result.name, 'Osteopatia');
  });

  test('criação exige resposta HTTP 201', () async {
    final client = FakeSpecialtyHttpClient(
      postResponse: const SpecialtyHttpResponse(
        statusCode: 201,
        body: {'id': '1', 'nome': 'Nova'},
      ),
    );

    final result = await SpecialtyApiRepository(client).create('Nova');

    expect(client.lastPath, '/api/especialidade');
    expect(client.lastBody, {'nome': 'Nova'});
    expect(client.lastAuthenticated, isTrue);
    expect(result.id, '1');
  });

  test('vínculo envia somente especialidadeId', () async {
    final client = FakeSpecialtyHttpClient(
      putResponse: const SpecialtyHttpResponse(statusCode: 200),
    );

    await SpecialtyApiRepository(client).updateProfessionalSpecialty('abc');

    expect(client.lastPath, '/api/profissional/especialidade');
    expect(client.lastBody, {'especialidadeId': 'abc'});
    expect(client.lastAuthenticated, isTrue);
  });

  test(
    'mapeia erros 400, 401, 403, 404 e 409 com mensagens específicas',
    () async {
      for (final entry in <int, SpecialtyFailure>{
        400: SpecialtyFailure.badRequest,
        401: SpecialtyFailure.unauthorized,
        403: SpecialtyFailure.forbidden,
        404: SpecialtyFailure.notFound,
        409: SpecialtyFailure.conflict,
      }.entries) {
        final client = FakeSpecialtyHttpClient(
          getResponse: SpecialtyHttpResponse(statusCode: entry.key),
        );

        await expectLater(
          SpecialtyApiRepository(client).getById('abc'),
          throwsA(
            isA<SpecialtyException>()
                .having((error) => error.failure, 'failure', entry.value)
                .having((error) => error.message, 'message', isNotEmpty),
          ),
        );
      }
    },
  );

  test('não duplica /api quando a base do cliente já possui o prefixo', () {
    expect(
      specialtyPathForBaseUrl('https://example.test/api', '/api/especialidade'),
      '/especialidade',
    );
    expect(
      specialtyPathForBaseUrl('https://example.test', '/api/especialidade'),
      '/api/especialidade',
    );
  });
}
