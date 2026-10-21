import 'package:agendaifisiomobile/app/app.dart';
import 'package:agendaifisiomobile/features/auth/data/auth_api.dart';
import 'package:agendaifisiomobile/features/auth/data/session_storage.dart';
import 'package:agendaifisiomobile/features/auth/domain/auth_session.dart';
import 'package:agendaifisiomobile/features/auth/presentation/controllers/session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('inicializa no login quando não existe sessão salva', (
    tester,
  ) async {
    final controller = SessionController(
      authGateway: _ProfessionalGateway(),
      storage: _MemoryStorage(),
    );

    await tester.pumpWidget(AgendaiFisioApp(sessionController: controller));
    await tester.pumpAndSettle();

    expect(find.text('Boas-vindas'), findsOneWidget);
    expect(find.text('Preparando seu acesso...'), findsNothing);
  });

  testWidgets('login profissional não abre a área exclusiva do paciente', (
    tester,
  ) async {
    final controller = SessionController(
      authGateway: _ProfessionalGateway(),
      storage: _MemoryStorage(),
    );
    await tester.pumpWidget(AgendaiFisioApp(sessionController: controller));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('login-email')),
      'fisio@example.com',
    );
    await tester.enterText(find.byKey(const Key('login-password')), 'segredo');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Login realizado'), findsOneWidget);
    expect(find.text('Profissional • fisio@example.com'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}

class _MemoryStorage implements SessionStorage {
  AuthSession? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<AuthSession?> read() async => value;

  @override
  Future<void> write(AuthSession session) async => value = session;
}

class _ProfessionalGateway implements AuthGateway {
  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async => AuthSession(
    accessToken: 'jwt-token',
    expiresAtUtc: DateTime.now().toUtc().add(const Duration(hours: 1)),
    user: const AuthenticatedUser(
      userId: 'user-1',
      profileId: 'professional-1',
      email: 'fisio@example.com',
      role: UserRole.professional,
    ),
  );

  @override
  Future<void> logout(String accessToken) async {}

  @override
  Future<AuthenticatedUser> me(String accessToken) async =>
      throw UnimplementedError();
}
