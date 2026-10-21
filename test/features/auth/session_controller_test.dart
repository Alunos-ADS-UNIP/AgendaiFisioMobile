import 'package:agendaifisiomobile/core/network/api_exception.dart';
import 'package:agendaifisiomobile/features/auth/data/auth_api.dart';
import 'package:agendaifisiomobile/features/auth/data/session_storage.dart';
import 'package:agendaifisiomobile/features/auth/domain/auth_session.dart';
import 'package:agendaifisiomobile/features/auth/presentation/controllers/session_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 10, 21, 12);

  group('SessionController', () {
    test('restaura uma sessão válida consultando /me', () async {
      final saved = _session(expiresAt: now.add(const Duration(hours: 1)));
      final storage = _MemoryStorage(saved);
      final gateway = _FakeAuthGateway(
        meResult: const AuthenticatedUser(
          userId: 'user-1',
          email: 'atualizado@example.com',
          role: UserRole.patient,
        ),
      );
      final controller = SessionController(
        authGateway: gateway,
        storage: storage,
        now: () => now,
      );

      await controller.restore();

      expect(controller.status, SessionStatus.authenticated);
      expect(controller.user?.email, 'atualizado@example.com');
      expect(gateway.meTokens, ['jwt-token']);
      expect(storage.value?.user.email, 'atualizado@example.com');
    });

    test('descarta sessão expirada sem chamar /me', () async {
      final storage = _MemoryStorage(
        _session(expiresAt: now.subtract(const Duration(seconds: 1))),
      );
      final gateway = _FakeAuthGateway();
      final controller = SessionController(
        authGateway: gateway,
        storage: storage,
        now: () => now,
      );
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.restore();

      expect(controller.status, SessionStatus.unauthenticated);
      expect(notifications, 2, reason: 'deve retirar a interface do splash');
      expect(storage.value, isNull);
      expect(gateway.meTokens, isEmpty);
    });

    test('login salva a sessão e disponibiliza somente o token cru', () async {
      final expected = _session(expiresAt: now.add(const Duration(hours: 1)));
      final storage = _MemoryStorage();
      final gateway = _FakeAuthGateway(loginResult: expected);
      final controller = SessionController(
        authGateway: gateway,
        storage: storage,
        now: () => now,
      );

      final success = await controller.login(
        email: 'ana@example.com',
        password: 'segredo',
      );

      expect(success, isTrue);
      expect(controller.status, SessionStatus.authenticated);
      expect(storage.value, same(expected));
      expect(await controller.tokenProvider(), 'jwt-token');
    });

    test('401 exibe mensagem amigável e não cria sessão', () async {
      final controller = SessionController(
        authGateway: _FakeAuthGateway(
          loginError: ApiException('detalhe interno', statusCode: 401),
        ),
        storage: _MemoryStorage(),
        now: () => now,
      );

      final success = await controller.login(
        email: 'ana@example.com',
        password: 'errada',
      );

      expect(success, isFalse);
      expect(controller.status, SessionStatus.unauthenticated);
      expect(controller.errorMessage, 'E-mail ou senha incorretos.');
      expect(controller.accessToken, isNull);
    });

    test('logout limpa a sessão mesmo quando a API falha', () async {
      final storage = _MemoryStorage();
      final gateway = _FakeAuthGateway(
        loginResult: _session(expiresAt: now.add(const Duration(hours: 1))),
        logoutError: Exception('offline'),
      );
      final controller = SessionController(
        authGateway: gateway,
        storage: storage,
        now: () => now,
      );
      await controller.login(email: 'ana@example.com', password: 'segredo');

      await controller.logout();

      expect(controller.status, SessionStatus.unauthenticated);
      expect(storage.value, isNull);
    });
  });
}

AuthSession _session({required DateTime expiresAt}) => AuthSession(
  accessToken: 'jwt-token',
  expiresAtUtc: expiresAt,
  user: const AuthenticatedUser(
    userId: 'user-1',
    profileId: 'patient-1',
    email: 'ana@example.com',
    role: UserRole.patient,
  ),
);

class _MemoryStorage implements SessionStorage {
  _MemoryStorage([this.value]);
  AuthSession? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<AuthSession?> read() async => value;

  @override
  Future<void> write(AuthSession session) async => value = session;
}

class _FakeAuthGateway implements AuthGateway {
  _FakeAuthGateway({
    this.loginResult,
    this.loginError,
    this.meResult,
    this.logoutError,
  });

  final AuthSession? loginResult;
  final Object? loginError;
  final AuthenticatedUser? meResult;
  final Object? logoutError;
  final List<String> meTokens = [];

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    if (loginError != null) throw loginError!;
    return loginResult!;
  }

  @override
  Future<void> logout(String accessToken) async {
    if (logoutError != null) throw logoutError!;
  }

  @override
  Future<AuthenticatedUser> me(String accessToken) async {
    meTokens.add(accessToken);
    return meResult!;
  }
}
