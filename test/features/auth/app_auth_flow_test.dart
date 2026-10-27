import 'package:agendaifisiomobile/app/app.dart';
import 'package:agendaifisiomobile/features/auth/data/auth_api.dart';
import 'package:agendaifisiomobile/features/auth/data/session_storage.dart';
import 'package:agendaifisiomobile/features/auth/domain/auth_session.dart';
import 'package:agendaifisiomobile/features/auth/presentation/controllers/session_controller.dart';
import 'package:agendaifisiomobile/core/network/api_client.dart';
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

    // Primeiro acesso: o perfil é completado antes da tela principal.
    expect(find.text('Editar perfil profissional'), findsOneWidget);
    expect(find.text('Especialidade'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
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

class _FakeProfessionalApi extends ProfessionalProfileApi {
  _FakeProfessionalApi() : super(ApiClient(baseUrl: 'http://localhost'));

  String? registeredEmail;

  @override
  Future<ProfessionalProfile> fetchOwnProfile() async =>
      const ProfessionalProfile(
        id: 'professional-1',
        name: 'Cadastro Pendente',
        email: 'fisio@example.com',
        crefito: '',
        phone: '',
        bio: '',
        specialtyName: '',
        isActive: true,
      );

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
