import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agendaifisiomobile/app/app.dart';
import 'package:agendaifisiomobile/core/network/api_client.dart';
import 'package:agendaifisiomobile/features/auth/data/auth_api.dart';
import 'package:agendaifisiomobile/features/auth/data/session_storage.dart';
import 'package:agendaifisiomobile/features/auth/domain/auth_session.dart';
import 'package:agendaifisiomobile/features/auth/presentation/controllers/session_controller.dart';
import 'package:agendaifisiomobile/features/professional_profile/data/professional_profile_api.dart';
import 'package:agendaifisiomobile/features/professional_profile/domain/professional_profile.dart';
import 'package:agendaifisiomobile/features/specialties/domain/entities/specialty.dart';
import 'package:agendaifisiomobile/features/specialties/domain/repositories/specialty_repository.dart';

void main() {
  testWidgets('catálogo público abre pela tela de login e retorna', (
    tester,
  ) async {
    final repository = NavigationSpecialtyRepository();
    await tester.pumpWidget(
      AgendaiFisioApp(
        sessionController: _sessionController(UserRole.patient),
        specialtyRepository: repository,
      ),
    );
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Consultar especialidades'));
    await tester.pumpAndSettle();
    expect(find.text('Especialidades'), findsOneWidget);
    expect(find.text('Ortopedia'), findsOneWidget);

    await tester.tap(find.text('Ortopedia'));
    await tester.pumpAndSettle();
    expect(find.text('Especialidade disponível: Ortopedia'), findsOneWidget);
    await tester.tap(find.text('Fechar'));
    await tester.pumpAndSettle();

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(find.text('Boas-vindas'), findsOneWidget);
  });

  testWidgets(
    'Profissional abre seleção pelo perfil e mantém seleção confirmada',
    (tester) async {
      final repository = NavigationSpecialtyRepository();
      final profileApi = NavigationProfessionalApi(repository);
      await tester.pumpWidget(
        AgendaiFisioApp(
          sessionController: _sessionController(UserRole.professional),
          professionalProfileApi: profileApi,
          specialtyRepository: repository,
        ),
      );
      await _login(tester);

      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alterar especialidade'));
      await tester.pumpAndSettle();
      expect(find.text('Minha especialidade'), findsOneWidget);

      await tester.tap(find.text('Ortopedia'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aquática'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar especialidade'));
      await tester.pumpAndSettle();

      expect(find.text('Meu perfil profissional'), findsOneWidget);
      expect(find.text('Aquática'), findsOneWidget);
      await tester.tap(find.text('Alterar especialidade'));
      await tester.pumpAndSettle();
      expect(find.text('Aquática'), findsWidgets);
    },
  );
}

Future<void> _login(WidgetTester tester) async {
  await tester.pumpAndSettle();
  if (find.byKey(const Key('login-email')).evaluate().isNotEmpty) {
    await tester.enterText(
      find.byKey(const Key('login-email')),
      'usuario@example.com',
    );
    await tester.enterText(find.byKey(const Key('login-password')), 'segredo');
    await tester.tap(find.text('Entrar'));
  }
  await tester.pumpAndSettle();
}

SessionController _sessionController(UserRole role) => SessionController(
  authGateway: _NavigationGateway(role),
  storage: _EmptyStorage(),
);

class NavigationSpecialtyRepository implements SpecialtyRepository {
  final items = <Specialty>[
    const Specialty(id: '1', name: 'Ortopedia'),
    const Specialty(id: '2', name: 'Aquática'),
  ];
  String? selectedId = '1';

  @override
  Future<List<Specialty>> list() async => List.unmodifiable(items);

  @override
  Future<Specialty> getById(String id) async =>
      items.firstWhere((item) => item.id == id);

  @override
  Future<void> updateProfessionalSpecialty(String specialtyId) async {
    selectedId = specialtyId;
  }
}

class NavigationProfessionalApi extends ProfessionalProfileApi {
  NavigationProfessionalApi(this.repository) : super(ApiClientForNavigation());

  final NavigationSpecialtyRepository repository;

  @override
  Future<ProfessionalProfile> fetchOwnProfile() async {
    final specialty = repository.items.firstWhere(
      (item) => item.id == repository.selectedId,
      orElse: () => repository.items.first,
    );
    return ProfessionalProfile(
      id: 'professional-1',
      name: 'Joana Silva',
      email: 'usuario@example.com',
      crefito: 'CREFITO-123',
      phone: '',
      bio: '',
      specialtyId: specialty.id,
      specialtyName: specialty.name,
      isActive: true,
    );
  }
}

class ApiClientForNavigation extends ApiClient {
  ApiClientForNavigation() : super(baseUrl: 'http://localhost');
}

class _NavigationGateway implements AuthGateway {
  _NavigationGateway(this.role);

  final UserRole role;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async => AuthSession(
    accessToken: 'navigation-token',
    expiresAtUtc: DateTime.now().toUtc().add(const Duration(hours: 1)),
    user: AuthenticatedUser(
      userId: 'user-1',
      profileId: 'profile-1',
      email: email,
      role: role,
    ),
  );

  @override
  Future<AuthenticatedUser> me(String accessToken) async =>
      throw UnimplementedError();

  @override
  Future<void> logout(String accessToken) async {}
}

class _EmptyStorage implements SessionStorage {
  @override
  Future<void> clear() async {}

  @override
  Future<AuthSession?> read() async => null;

  @override
  Future<void> write(AuthSession session) async {}
}
