import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agendaifisiomobile/core/theme/app_theme.dart';
import 'package:agendaifisiomobile/features/specialties/domain/entities/specialty.dart';
import 'package:agendaifisiomobile/features/specialties/domain/repositories/specialty_repository.dart';
import 'package:agendaifisiomobile/features/specialties/domain/specialty_failure.dart';
import 'package:agendaifisiomobile/features/specialties/presentation/controllers/specialty_controller.dart';
import 'package:agendaifisiomobile/features/specialties/presentation/pages/clinic_specialties_page.dart';
import 'package:agendaifisiomobile/features/specialties/presentation/pages/professional_specialty_page.dart';
import 'package:agendaifisiomobile/features/specialties/presentation/pages/specialty_list_page.dart';
import 'package:agendaifisiomobile/features/specialties/presentation/widgets/specialty_picker_sheet.dart';

class WidgetSpecialtyRepository implements SpecialtyRepository {
  WidgetSpecialtyRepository({this.items = const []});

  List<Specialty> items;
  bool failList = false;
  bool failSave = false;
  bool failCreate = false;
  String? savedId;
  String? createdName;

  @override
  Future<List<Specialty>> list() async {
    if (failList) {
      throw const SpecialtyException(
        SpecialtyFailure.network,
        'Sem conexão com o servidor.',
      );
    }
    return items;
  }

  @override
  Future<Specialty> getById(String id) async =>
      items.firstWhere((item) => item.id == id);

  @override
  Future<Specialty> create(String name) async {
    if (failCreate) {
      throw const SpecialtyException(
        SpecialtyFailure.conflict,
        'Conflito: esta especialidade já existe.',
      );
    }
    createdName = name;
    return Specialty(id: 'created', name: name);
  }

  @override
  Future<void> updateProfessionalSpecialty(String specialtyId) async {
    if (failSave) {
      throw const SpecialtyException(
        SpecialtyFailure.conflict,
        'Conflito ao atualizar especialidade.',
      );
    }
    savedId = specialtyId;
  }
}

Widget _app(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

Future<void> _pumpPage(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(_app(child));
  await tester.pump();
}

void main() {
  final items = const [
    Specialty(id: '1', name: 'Ortopedia'),
    Specialty(id: '2', name: 'Aquática'),
  ];

  testWidgets('catálogo público carrega e filtra por nome', (tester) async {
    final repository = WidgetSpecialtyRepository(items: items);
    final controller = SpecialtyCatalogController(repository: repository);

    await _pumpPage(tester, SpecialtyListPage(controller: controller));

    expect(find.text('Especialidades'), findsOneWidget);
    expect(find.text('Ortopedia'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'aquática');
    await tester.pump();

    expect(find.text('Aquática'), findsOneWidget);
    expect(find.text('Ortopedia'), findsNothing);
    controller.dispose();
  });

  testWidgets('catálogo exibe vazio, erro e offline com retry', (tester) async {
    final repository = WidgetSpecialtyRepository();
    final controller = SpecialtyCatalogController(repository: repository);
    await _pumpPage(tester, SpecialtyListPage(controller: controller));
    expect(find.text('Nenhuma especialidade encontrada'), findsOneWidget);

    repository.failList = true;
    await tester.tap(find.byTooltip('Atualizar catálogo'));
    await tester.pumpAndSettle();
    expect(find.text('Sem conexão'), findsOneWidget);
    expect(find.text('Sem conexão com o servidor.'), findsOneWidget);

    repository.failList = false;
    repository.items = items;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Ortopedia'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('picker permite pesquisa e seleção única', (tester) async {
    Specialty? selected;
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                selected = await SpecialtyPickerSheet.show(
                  context,
                  items: items,
                );
              },
              child: const Text('Abrir picker'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir picker'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'aquática');
    await tester.pump();
    await tester.tap(find.text('Aquática'));
    await tester.pumpAndSettle();

    expect(selected, items[1]);
  });

  testWidgets('vínculo profissional só confirma a seleção após sucesso', (
    tester,
  ) async {
    final repository = WidgetSpecialtyRepository(items: items)..failSave = true;
    final catalog = SpecialtyCatalogController(repository: repository);
    final professional = ProfessionalSpecialtyController(
      repository: repository,
      initialId: '1',
    );

    await _pumpPage(
      tester,
      ProfessionalSpecialtyPage(
        catalogController: catalog,
        professionalController: professional,
      ),
    );
    await tester.tap(find.text('Salvar especialidade'));
    await tester.pumpAndSettle();
    expect(professional.selectedId, '1');
    expect(find.text('Conflito ao atualizar especialidade.'), findsWidgets);

    repository.failSave = false;
    await tester.tap(find.text('Salvar especialidade'));
    await tester.pumpAndSettle();
    expect(repository.savedId, '1');
    expect(professional.selectedId, '1');
    catalog.dispose();
    professional.dispose();
  });

  testWidgets('Clínica cria e não duplica visualmente', (tester) async {
    final repository = WidgetSpecialtyRepository(items: items);
    final catalog = SpecialtyCatalogController(repository: repository);
    final clinic = ClinicSpecialtyController(repository: repository);

    await _pumpPage(
      tester,
      ClinicSpecialtiesPage(
        catalogController: catalog,
        clinicController: clinic,
        canCreate: true,
      ),
    );
    await tester.tap(find.text('Nova especialidade'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Nova Área');
    await tester.tap(find.text('Cadastrar'));
    await tester.pumpAndSettle();

    expect(repository.createdName, 'Nova Área');
    expect(find.text('Nova Área'), findsOneWidget);
    expect(find.text('Especialidade cadastrada com sucesso.'), findsOneWidget);
    catalog.dispose();
    clinic.dispose();
  });

  testWidgets('Paciente ou Profissional não visualizam a ação administrativa', (
    tester,
  ) async {
    final repository = WidgetSpecialtyRepository(items: items);
    final catalog = SpecialtyCatalogController(repository: repository);
    final clinic = ClinicSpecialtyController(repository: repository);

    await _pumpPage(
      tester,
      ClinicSpecialtiesPage(
        catalogController: catalog,
        clinicController: clinic,
        canCreate: false,
      ),
    );

    expect(find.text('Acesso restrito'), findsOneWidget);
    expect(find.text('Nova especialidade'), findsNothing);
    catalog.dispose();
    clinic.dispose();
  });

  testWidgets('catálogo cabe em 360 px com texto ampliado a 150%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final catalog = SpecialtyCatalogController(
      repository: WidgetSpecialtyRepository(items: items),
    );
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
        child: _app(SpecialtyListPage(controller: catalog)),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    catalog.dispose();
  });
}
