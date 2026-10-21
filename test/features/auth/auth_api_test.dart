import 'dart:convert';

import 'package:agendaifisiomobile/core/network/api_exception.dart';
import 'package:agendaifisiomobile/features/auth/data/auth_api.dart';
import 'package:agendaifisiomobile/features/auth/domain/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('AuthApi', () {
    test('login envia o contrato esperado e converte a sessão', () async {
      late http.Request captured;
      final api = AuthApi(
        baseUrl: 'http://api.test',
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'accessToken': 'jwt-token',
              'tokenType': 'Bearer',
              'expiresAtUtc': '2030-01-01T12:00:00Z',
              'usuario': {
                'usuarioId': 'user-1',
                'perfilId': 'patient-1',
                'email': 'ana@example.com',
                'tipoUsuario': 'Paciente',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final session = await api.login(
        email: ' ana@example.com ',
        password: 'segredo',
      );

      expect(captured.method, 'POST');
      expect(captured.url.path, '/api/Auth/login');
      expect(captured.headers['authorization'], isNull);
      expect(jsonDecode(captured.body), {
        'email': 'ana@example.com',
        'senha': 'segredo',
      });
      expect(session.accessToken, 'jwt-token');
      expect(session.user.role, UserRole.patient);
    });

    test('me envia Bearer e converte o perfil', () async {
      late http.Request captured;
      final api = AuthApi(
        baseUrl: 'http://api.test',
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'usuarioId': 'user-2',
              'email': 'fisio@example.com',
              'tipoUsuario': 'Profissional',
            }),
            200,
          );
        }),
      );

      final user = await api.me('jwt-token');

      expect(captured.headers['authorization'], 'Bearer jwt-token');
      expect(user.role, UserRole.professional);
    });

    test('401 de login vira erro de credenciais sem vazar resposta', () async {
      final api = AuthApi(
        baseUrl: 'http://api.test',
        client: MockClient(
          (_) async => http.Response(jsonEncode({'Erro': 'Inválido'}), 401),
        ),
      );

      await expectLater(
        api.login(email: 'ana@example.com', password: 'errada'),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'status', 401)
              .having((error) => error.message, 'message', 'Inválido'),
        ),
      );
    });
  });
}
