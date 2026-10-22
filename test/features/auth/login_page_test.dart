import 'package:agendaifisiomobile/core/network/api_exception.dart';
import 'package:agendaifisiomobile/core/theme/app_theme.dart';
import 'package:agendaifisiomobile/features/auth/data/auth_api.dart';
import 'package:agendaifisiomobile/features/auth/data/session_storage.dart';
import 'package:agendaifisiomobile/features/auth/domain/auth_session.dart';
import 'package:agendaifisiomobile/features/auth/presentation/controllers/session_controller.dart';
import 'package:agendaifisiomobile/features/auth/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('valida campos obrigatórios e formato do e-mail', (tester) async {
    final controller = await _controller();
    await _pumpLogin(tester, controller);

    await tester.tap(find.text('Entrar'));
    await tester.pump();
    expect(find.text('Informe seu e-mail.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('login-email')),
      'email-invalido',
    );
    await tester.enterText(find.byKey(const Key('login-password')), '123');
    await tester.tap(find.text('Entrar'));
    await tester.pump();
    expect(find.text('Digite um e-mail válido.'), findsOneWidget);
    expect(
      find.text('A senha precisa ter pelo menos 6 caracteres.'),
      findsOneWidget,
    );
  });

  testWidgets('permite mostrar e ocultar a senha', (tester) async {
    final controller = await _controller();
    await _pumpLogin(tester, controller);

    TextField field() => tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('login-password')),
        matching: find.byType(TextField),
      ),
    );

    expect(field().obscureText, isTrue);
    await tester.tap(find.byTooltip('Mostrar senha'));
    await tester.pump();
    expect(field().obscureText, isFalse);
  });

  testWidgets('exibe erro de credenciais e o limpa ao editar', (tester) async {
    final controller = await _controller(
      gateway: _LoginGateway(error: ApiException('inválido', statusCode: 401)),
    );
    await _pumpLogin(tester, controller);
    await tester.enterText(
      find.byKey(const Key('login-email')),
      'ana@example.com',
    );
    await tester.enterText(find.byKey(const Key('login-password')), 'segredo');

    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('login-password')),
      'outra-senha',
    );
    await tester.pump();
    expect(find.text('E-mail ou senha incorretos.'), findsNothing);
  });

  testWidgets('avisa que a sessão expirou e some ao editar', (tester) async {
    final controller = await _controller(gateway: _LoginGateway(session: _ok));
    await controller.login(email: 'ana@example.com', password: 'segredo');
    await controller.expireSession();
    await _pumpLogin(tester, controller);

    expect(find.byKey(const Key('session-expired-notice')), findsOneWidget);
    expect(find.textContaining('Sua sessão expirou'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('login-email')), 'a');
    await tester.pump();
    expect(find.byKey(const Key('session-expired-notice')), findsNothing);
  });

  testWidgets('não apresenta overflow em iPhone compacto', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = await _controller();

    await _pumpLogin(tester, controller);
    expect(tester.takeException(), isNull);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -350),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Criar conta'), findsOneWidget);
  });
}

Future<SessionController> _controller({_LoginGateway? gateway}) async {
  final controller = SessionController(
    authGateway: gateway ?? _LoginGateway(),
    storage: _EmptyStorage(),
  );
  await controller.restore();
  return controller;
}

Future<void> _pumpLogin(
  WidgetTester tester,
  SessionController controller,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: LoginPage(controller: controller, onCreateAccount: () {}),
    ),
  );
  await tester.pump();
}

class _EmptyStorage implements SessionStorage {
  @override
  Future<void> clear() async {}

  @override
  Future<AuthSession?> read() async => null;

  @override
  Future<void> write(AuthSession session) async {}
}

class _LoginGateway implements AuthGateway {
  _LoginGateway({this.error, this.session});
  final Object? error;
  final AuthSession? session;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    if (error != null) throw error!;
    if (session != null) return session!;
    throw UnimplementedError();
  }

  @override
  Future<void> logout(String accessToken) async {}

  @override
  Future<AuthenticatedUser> me(String accessToken) async =>
      throw UnimplementedError();
}

final _ok = AuthSession(
  accessToken: 'jwt-token',
  expiresAtUtc: DateTime.now().toUtc().add(const Duration(hours: 1)),
  user: const AuthenticatedUser(
    userId: 'user-1',
    profileId: 'patient-1',
    email: 'ana@example.com',
    role: UserRole.patient,
  ),
);
