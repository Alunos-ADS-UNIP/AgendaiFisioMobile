import 'package:flutter_test/flutter_test.dart';

import 'package:agendaifisiomobile/features/specialties/domain/entities/specialty.dart';
import 'package:agendaifisiomobile/features/specialties/domain/repositories/specialty_repository.dart';
import 'package:agendaifisiomobile/features/specialties/domain/specialty_failure.dart';
import 'package:agendaifisiomobile/features/specialties/presentation/controllers/specialty_controller.dart';

class FakeSpecialtyRepository implements SpecialtyRepository {
  List<Specialty> items = const [Specialty(id: '1', name: 'Ortopedia')];
  bool failUpdate = false;
  bool failList = false;
  String? savedId;
  String? createdName;

  @override
  Future<List<Specialty>> list() async {
    if (failList) {
      throw const SpecialtyException(SpecialtyFailure.network, 'Sem conexão.');
    }
    return items;
  }

  @override
  Future<Specialty> getById(String id) async => items.first;

  @override
  Future<Specialty> create(String name) async {
    createdName = name;
    return Specialty(id: '2', name: name);
  }

  @override
  Future<void> updateProfessionalSpecialty(String specialtyId) async {
    if (failUpdate) {
      throw const SpecialtyException(
        SpecialtyFailure.conflict,
        'Conflito de teste.',
      );
    }
    savedId = specialtyId;
  }
}

void main() {
  test('carrega catálogo e deduplica por nome normalizado', () async {
    final repository = FakeSpecialtyRepository()
      ..items = const [
        Specialty(id: '1', name: 'Aquática'),
        Specialty(id: '2', name: '  AQUATICA '),
      ];
    final controller = SpecialtyCatalogController(repository: repository);

    await controller.load();

    expect(controller.state.status, SpecialtyCatalogStatus.loaded);
    expect(controller.state.items, hasLength(1));
    controller.dispose();
  });

  test('representa catálogo vazio', () async {
    final controller = SpecialtyCatalogController(
      repository: FakeSpecialtyRepository()..items = const [],
    );

    await controller.load();

    expect(controller.state.status, SpecialtyCatalogStatus.empty);
    controller.dispose();
  });

  test('representa falha de rede como estado offline recuperável', () async {
    final controller = SpecialtyCatalogController(
      repository: FakeSpecialtyRepository()..failList = true,
    );

    await controller.load();

    expect(controller.state.status, SpecialtyCatalogStatus.offline);
    expect(controller.state.errorMessage, 'Sem conexão.');
    controller.dispose();
  });

  test('criação duplicada não altera o catálogo local', () async {
    final repository = FakeSpecialtyRepository();
    final controller = SpecialtyCatalogController(repository: repository);
    await controller.load();

    controller.addCreated(const Specialty(id: '2', name: ' ORTOPEDIA '));

    expect(controller.state.items, hasLength(1));
    controller.dispose();
  });

  test('só atualiza seleção após sucesso do repository', () async {
    final repository = FakeSpecialtyRepository()..failUpdate = true;
    final controller = ProfessionalSpecialtyController(
      repository: repository,
      initialId: 'old',
    );

    expect(await controller.save('new'), isFalse);
    expect(controller.selectedId, 'old');

    repository.failUpdate = false;
    expect(await controller.save('new'), isTrue);
    expect(controller.selectedId, 'new');
    controller.dispose();
  });

  test('cadastro retorna item somente após o repository confirmar', () async {
    final repository = FakeSpecialtyRepository();
    final controller = ClinicSpecialtyController(repository: repository);

    final created = await controller.create('Nova Área');

    expect(created?.name, 'Nova Área');
    expect(repository.createdName, 'Nova Área');
    controller.dispose();
  });
}
