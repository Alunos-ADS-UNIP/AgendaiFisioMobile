import 'package:agendaifisiomobile/core/theme/app_theme.dart';
import 'package:agendaifisiomobile/development/appointment_preview_repository.dart';
import 'package:agendaifisiomobile/features/professional_profile/data/dtos/professional_profile_dtos.dart';
import 'package:agendaifisiomobile/features/professional_profile/data/professional_profile_api.dart';
import 'package:agendaifisiomobile/features/professional_profile/domain/professional_profile.dart';
import 'package:agendaifisiomobile/features/professional_profile/presentation/controllers/professional_profile_controller.dart';
import 'package:agendaifisiomobile/features/professional_profile/presentation/pages/professional_profile_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeApi implements ProfessionalProfileApi {
  final calls = <String>[];
  String? specialtyId;

  @override
  Future<({String cpf, DateTime? birthDate})?> fetchOwnPrivateData() async =>
      null;

  @override
  Future<ProfessionalProfile> fetchOwnProfile() async =>
      const ProfessionalProfile(
        id: 'p1',
        name: 'Cadastro Pendente',
        email: 'a@b.com',
        crefito: '',
        phone: '',
        bio: '',
        specialtyName: '',
        isActive: true,
      );

  @override
  Future<void> updateOwnProfile(ProfessionalUpdateRequest request) async =>
      calls.add('perfil');

  @override
  Future<void> updateOwnSpecialty(String id) async {
    specialtyId = id;
    calls.add('especialidade');
  }

  @override
  Future<void> register(ProfessionalRegisterRequest request) async {}
}

void main() {
  test('envia a especialidade antes do perfil e atualiza o nome', () async {
    final api = _FakeApi();
    final c = ProfessionalProfileController(api);
    await c.load();
    final ok = await c.submit(
      ProfessionalUpdateRequest(
        name: 'Marina Lopes',
        cpf: '12345678901',
        crefito: 'CREFITO-1',
        phone: '16999999999',
        birthDate: DateTime(1990, 1, 1),
        bio: '',
        isActive: true,
      ),
      specialtyId: 'esportiva',
      specialtyName: 'Fisioterapia esportiva',
    );
    expect(ok, isTrue);
    expect(api.calls, ['especialidade', 'perfil']);
    expect(api.specialtyId, 'esportiva');
    expect(c.profile!.specialtyName, 'Fisioterapia esportiva');
    expect(c.profile!.isPendingCompletion, isFalse);
  });

  testWidgets('formulário mostra o campo Especialidade e o seletor', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = ProfessionalProfileController(_FakeApi());
    await c.load();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ProfessionalProfileFormPage(
          controller: c,
          onSaved: () {},
          onSessionExpired: () {},
          specialtyRepository: AppointmentPreviewRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Especialidade'), findsOneWidget);

    await tester.tap(find.text('Especialidade'));
    await tester.pumpAndSettle();
    expect(find.text('Escolha uma especialidade'), findsOneWidget);
    await tester.tap(find.text('Fisioterapia esportiva'));
    await tester.pumpAndSettle();
    expect(find.text('Fisioterapia esportiva'), findsOneWidget);
  });
}
