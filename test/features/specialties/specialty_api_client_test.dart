import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:agendaifisiomobile/core/network/api_client.dart';
import 'package:agendaifisiomobile/features/auth/data/auth_api.dart';
import 'package:agendaifisiomobile/features/auth/data/session_storage.dart';
import 'package:agendaifisiomobile/features/auth/domain/auth_session.dart';
import 'package:agendaifisiomobile/features/auth/presentation/controllers/session_controller.dart';
import 'package:agendaifisiomobile/features/specialties/data/specialty_api_client.dart';

void main() {
  test('GET público não envia Authorization', () async {
    late http.BaseRequest captured;
    final client = ApiSpecialtyHttpClient(
      apiClient: ApiClient(
        baseUrl: 'https://example.test',
        authHeaderProvider: () async => fail('não deve ler o token'),
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(jsonEncode([]), 200);
        }),
      ),
    );

    final response = await client.get(
      '/api/especialidade',
      authenticated: false,
    );

    expect(response.statusCode, 200);
    expect(response.body, isEmpty);
    expect(captured.url.toString(), 'https://example.test/api/especialidade');
    expect(captured.headers.containsKey('Authorization'), isFalse);
  });

  test('GET por GUID usa a rota pública correta', () async {
    late http.BaseRequest captured;
    final client = ApiSpecialtyHttpClient(
      apiClient: ApiClient(
        baseUrl: 'https://example.test',
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({'id': 'guid', 'nome': 'Ortopedia'}),
            200,
          );
        }),
      ),
    );

    await client.get(
      '/api/especialidade/550e8400-e29b-41d4-a716-446655440000',
      authenticated: false,
    );

    expect(
      captured.url.toString(),
      'https://example.test/api/especialidade/'
      '550e8400-e29b-41d4-a716-446655440000',
    );
  });

  test('POST envia body correto e Authorization', () async {
    late http.Request captured;
    final client = ApiSpecialtyHttpClient(
      apiClient: ApiClient(
        baseUrl: 'https://example.test',
        authHeaderProvider: () async => 'jwt-token',
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(jsonEncode({'id': '1', 'nome': 'Nova'}), 201);
        }),
      ),
    );

    final response = await client.post('/api/especialidade', {
      'nome': 'Nova',
    }, authenticated: true);

    expect(response.statusCode, 201);
    expect(captured.method, 'POST');
    expect(captured.url.path, '/api/especialidade');
    expect(jsonDecode(captured.body), {'nome': 'Nova'});
    expect(captured.headers['Authorization'], 'Bearer jwt-token');
  });

  test('PUT envia somente especialidadeId e Authorization', () async {
    late http.Request captured;
    final client = ApiSpecialtyHttpClient(
      apiClient: ApiClient(
        baseUrl: 'https://example.test',
        authHeaderProvider: () async => 'jwt-token',
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response('', 204);
        }),
      ),
    );

    final response = await client.put('/api/profissional/especialidade', {
      'especialidadeId': 'specialty-guid',
    }, authenticated: true);

    expect(response.statusCode, 204);
    expect(captured.method, 'PUT');
    expect(jsonDecode(captured.body), {'especialidadeId': 'specialty-guid'});
    expect(captured.headers['Authorization'], 'Bearer jwt-token');
  });

  test('PUT aceita resposta 200 do vínculo', () async {
    final client = ApiSpecialtyHttpClient(
      apiClient: ApiClient(
        baseUrl: 'https://example.test',
        authHeaderProvider: () async => 'jwt-token',
        httpClient: MockClient((request) async {
          expect(request.method, 'PUT');
          expect(jsonDecode(request.body), {
            'especialidadeId': 'specialty-guid',
          });
          return http.Response('', 200);
        }),
      ),
    );

    final response = await client.put('/api/profissional/especialidade', {
      'especialidadeId': 'specialty-guid',
    }, authenticated: true);

    expect(response.statusCode, 200);
  });

  test('401 chama expiração de sessão e preserva o status', () async {
    var expirationCalls = 0;
    final client = ApiSpecialtyHttpClient(
      apiClient: ApiClient(
        baseUrl: 'https://example.test',
        authHeaderProvider: () async => 'expired-token',
        httpClient: MockClient((_) async => http.Response('', 401)),
      ),
      onUnauthorized: () async => expirationCalls++,
    );

    final response = await client.put('/api/profissional/especialidade', {
      'especialidadeId': 'specialty-guid',
    }, authenticated: true);

    expect(response.statusCode, 401);
    expect(expirationCalls, 1);
  });

  test('401 expira a sessão pelo SessionController real', () async {
    final session = SessionController(
      authGateway: _SessionGateway(),
      storage: _MemorySessionStorage(),
    );
    await session.login(email: 'user@example.com', password: 'secret');
    expect(session.status, SessionStatus.authenticated);

    final client = ApiSpecialtyHttpClient(
      apiClient: ApiClient(
        baseUrl: 'https://example.test',
        authHeaderProvider: session.tokenProvider,
        httpClient: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer session-token');
          return http.Response('', 401);
        }),
      ),
      onUnauthorized: session.expireSession,
    );

    await client.put('/api/profissional/especialidade', {
      'especialidadeId': 'specialty-guid',
    }, authenticated: true);

    expect(session.status, SessionStatus.unauthenticated);
    expect(session.sessionExpired, isTrue);
  });

  test('403 não expira a sessão', () async {
    var expirationCalls = 0;
    final client = ApiSpecialtyHttpClient(
      apiClient: ApiClient(
        baseUrl: 'https://example.test',
        authHeaderProvider: () async => 'token',
        httpClient: MockClient((_) async => http.Response('', 403)),
      ),
      onUnauthorized: () async => expirationCalls++,
    );

    final response = await client.post('/api/especialidade', {
      'nome': 'Nova',
    }, authenticated: true);

    expect(response.statusCode, 403);
    expect(expirationCalls, 0);
  });

  test('403 mantém a sessão autenticada no SessionController real', () async {
    final session = SessionController(
      authGateway: _SessionGateway(),
      storage: _MemorySessionStorage(),
    );
    await session.login(email: 'user@example.com', password: 'secret');

    final client = ApiSpecialtyHttpClient(
      apiClient: ApiClient(
        baseUrl: 'https://example.test',
        authHeaderProvider: session.tokenProvider,
        httpClient: MockClient((_) async => http.Response('', 403)),
      ),
      onUnauthorized: session.expireSession,
    );

    await client.post('/api/especialidade', {
      'nome': 'Nova',
    }, authenticated: true);

    expect(session.status, SessionStatus.authenticated);
    expect(session.sessionExpired, isFalse);
  });

  test('preserva status 400, 404, 409 e 500', () async {
    for (final status in [400, 404, 409, 500]) {
      final client = ApiSpecialtyHttpClient(
        apiClient: ApiClient(
          baseUrl: 'https://example.test',
          httpClient: MockClient((_) async => http.Response('', status)),
        ),
      );

      final response = await client.get(
        '/api/especialidade',
        authenticated: false,
      );

      expect(response.statusCode, status);
    }
  });

  test('propaga falha de rede para o repositório mapear como offline', () {
    final client = ApiSpecialtyHttpClient(
      apiClient: ApiClient(
        baseUrl: 'https://example.test',
        httpClient: MockClient((_) async {
          throw http.ClientException('offline');
        }),
      ),
    );

    expect(
      client.get('/api/especialidade', authenticated: false),
      throwsA(isA<http.ClientException>()),
    );
  });

  test('não duplica /api quando a base já termina em /api', () async {
    late http.BaseRequest captured;
    final client = ApiSpecialtyHttpClient(
      apiClient: ApiClient(
        baseUrl: 'https://example.test/api',
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(jsonEncode([]), 200);
        }),
      ),
    );

    await client.get('/api/especialidade', authenticated: false);

    expect(captured.url.toString(), 'https://example.test/especialidade');
    expect(captured.url.path.contains('/api/api'), isFalse);
  });
}

class _SessionGateway implements AuthGateway {
  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    return AuthSession(
      accessToken: 'session-token',
      expiresAtUtc: DateTime.now().toUtc().add(const Duration(hours: 1)),
      user: AuthenticatedUser(
        userId: 'user-1',
        profileId: 'profile-1',
        email: email,
        role: UserRole.professional,
      ),
    );
  }

  @override
  Future<AuthenticatedUser> me(String accessToken) async =>
      throw UnimplementedError();

  @override
  Future<void> logout(String accessToken) async {}
}

class _MemorySessionStorage implements SessionStorage {
  AuthSession? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<AuthSession?> read() async => value;

  @override
  Future<void> write(AuthSession session) async => value = session;
}
