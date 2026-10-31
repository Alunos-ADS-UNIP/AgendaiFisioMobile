import 'package:agendaifisiomobile/app/app.dart';
import 'package:agendaifisiomobile/features/auth/data/auth_api.dart';
import 'package:agendaifisiomobile/features/auth/data/session_storage.dart';
import 'package:agendaifisiomobile/features/auth/domain/auth_session.dart';
import 'package:agendaifisiomobile/features/auth/presentation/controllers/session_controller.dart';
import 'package:agendaifisiomobile/core/network/api_client.dart';
import 'package:agendaifisiomobile/core/network/api_exception.dart';
import 'package:agendaifisiomobile/features/professional_profile/data/dtos/professional_profile_dtos.dart';
import 'package:agendaifisiomobile/features/professional_profile/data/professional_profile_api.dart';
import 'package:agendaifisiomobile/features/professional_profile/domain/professional_profile.dart';
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

    await tester.pumpWidget(
      AgendaiFisioApp(
        sessionController: controller,
        professionalProfileApi: _FakeProfessionalApi(),
      ),
    );
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
    await tester.pumpWidget(
      AgendaiFisioApp(
        sessionController: controller,
        professionalProfileApi: _FakeProfessionalApi(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('login-email')),
      'fisio@example.com',
    );
    await tester.enterText(find.byKey(const Key('login-password')), 'segredo');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    // A home do profissional vem primeiro; o perfil abre pelo atalho.
    await _openProfessionalProfile(tester);

    expect(find.text('Meu perfil profissional'), findsOneWidget);
    expect(find.text('Complete seus dados profissionais para começar.'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('401 no perfil encerra a sessão e o login avisa a expiração', (
    tester,
  ) async {
    final controller = SessionController(
      authGateway: _ProfessionalGateway(),
      storage: _MemoryStorage(),
    );
    await tester.pumpWidget(
      AgendaiFisioApp(
        sessionController: controller,
        professionalProfileApi: _FakeProfessionalApi(
          fetchError: ApiException('Sessão expirada.', statusCode: 401),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _login(tester);

    await _openProfessionalProfile(tester);

    expect(controller.status, SessionStatus.unauthenticated);
    expect(controller.sessionExpired, isTrue);
    expect(find.text('Boas-vindas'), findsOneWidget);
    expect(find.byKey(const Key('session-expired-notice')), findsOneWidget);
    // A tela do perfil empilhada não pode ficar por cima do login.
    expect(find.text('Meu perfil profissional'), findsNothing);

    // Editar o e-mail remove o aviso.
    await tester.enterText(find.byKey(const Key('login-email')), 'a');
    await tester.pump();
    expect(find.byKey(const Key('session-expired-notice')), findsNothing);
  });

  testWidgets('logout voluntário não mostra o aviso de sessão expirada', (
    tester,
  ) async {
    final controller = SessionController(
      authGateway: _ProfessionalGateway(),
      storage: _MemoryStorage(),
    );
    await tester.pumpWidget(
      AgendaiFisioApp(
        sessionController: controller,
        professionalProfileApi: _FakeProfessionalApi(),
      ),
    );
    await tester.pumpAndSettle();
    await _login(tester);
    await _openProfessionalProfile(tester);

    await tester.tap(find.byTooltip('Sair'));
    await tester.pumpAndSettle();

    expect(controller.status, SessionStatus.unauthenticated);
    expect(find.text('Boas-vindas'), findsOneWidget);
    expect(find.byKey(const Key('session-expired-notice')), findsNothing);
  });

  testWidgets('cadastro profissional fica disponível pelo login', (
    tester,
  ) async {
    final controller = SessionController(
      authGateway: _ProfessionalGateway(),
      storage: _MemoryStorage(),
    );
    final api = _FakeProfessionalApi();
    await tester.pumpWidget(
      AgendaiFisioApp(
        sessionController: controller,
        professionalProfileApi: api,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sou fisioterapeuta'));
    await tester.pumpAndSettle();
    expect(find.text('Cadastro de fisioterapeuta'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'E-mail'),
      'novo@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Senha'),
      'segredo123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirmar senha'),
      'segredo123',
    );
    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();

    expect(api.registeredEmail, 'novo@example.com');
    expect(find.text('Boas-vindas'), findsOneWidget);
    expect(
      find.text('Conta criada. Entre para completar seu perfil.'),
      findsOneWidget,
    );
  });
}

Future<void> _login(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('login-email')),
    'fisio@example.com',
  );
  await tester.enterText(find.byKey(const Key('login-password')), 'segredo');
  await tester.tap(find.text('Entrar'));
  await tester.pumpAndSettle();
}

Future<void> _openProfessionalProfile(WidgetTester tester) async {
  // A lista da home é preguiçosa: numa tela alta o atalho "Perfil" já é
  // construído, sem precisar rolar.
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Perfil'));
  await tester.pumpAndSettle();
}

class _FakeProfessionalApi extends ProfessionalProfileApi {
  _FakeProfessionalApi({this.fetchError})
    : super(ApiClient(baseUrl: 'http://localhost'));

  final Object? fetchError;
  String? registeredEmail;

  @override
  Future<ProfessionalProfile> fetchOwnProfile() async {
    if (fetchError != null) throw fetchError!;
    return const ProfessionalProfile(
        id: 'professional-1',
        name: 'Cadastro Pendente',
        email: 'fisio@example.com',
        crefito: '',
        phone: '',
        bio: '',
        specialtyName: '',
        isActive: true,
      );
  }

  @override
  Future<void> register(ProfessionalRegisterRequest request) async {
    registeredEmail = request.email;
  }
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
