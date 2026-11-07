import 'package:flutter_test/flutter_test.dart';

import 'package:agendaifisiomobile/features/specialties/domain/entities/specialty.dart';
import 'package:agendaifisiomobile/features/specialties/domain/repositories/specialty_repository.dart';
import 'package:agendaifisiomobile/features/specialties/domain/specialty_failure.dart';
import 'package:agendaifisiomobile/features/specialties/presentation/controllers/specialty_controller.dart';

class FakeSpecialtyRepository implements SpecialtyRepository {
  List<Specialty> items = const [Specialty(id: '1', name: 'Ortopedia')];
  bool failUpdate = false;
  SpecialtyFailure updateFailure = SpecialtyFailure.conflict;
  bool failList = false;
  String? savedId;

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
  Future<void> updateProfessionalSpecialty(String specialtyId) async {
    if (failUpdate) {
      throw SpecialtyException(
        updateFailure,
        updateFailure == SpecialtyFailure.forbidden
            ? 'Você não tem permissão para realizar esta ação.'
            : 'Conflito de teste.',
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

  test('403 preserva seleção confirmada e apresenta acesso negado', () async {
    final repository = FakeSpecialtyRepository()
      ..failUpdate = true
      ..updateFailure = SpecialtyFailure.forbidden;
    final controller = ProfessionalSpecialtyController(
      repository: repository,
      initialId: 'confirmed',
    );

    expect(await controller.save('new'), isFalse);
    expect(controller.selectedId, 'confirmed');
    expect(
      controller.errorMessage,
      'Você não tem permissão para realizar esta ação.',
    );
    controller.dispose();
  });

  test(
    'falhas 400, 401, 409, 500 e rede preservam seleção e permitem retry',
    () async {
      for (final failure in [
        SpecialtyFailure.badRequest,
        SpecialtyFailure.unauthorized,
        SpecialtyFailure.conflict,
        SpecialtyFailure.unexpected,
        SpecialtyFailure.network,
      ]) {
        final repository = FakeSpecialtyRepository()
          ..failUpdate = true
          ..updateFailure = failure;
        final controller = ProfessionalSpecialtyController(
          repository: repository,
          initialId: 'confirmed',
        );

        expect(await controller.save('attempted'), isFalse);
        expect(controller.selectedId, 'confirmed');

        repository.failUpdate = false;
        expect(await controller.save('confirmed-after-retry'), isTrue);
        expect(controller.selectedId, 'confirmed-after-retry');
        controller.dispose();
      }
    },
  );
}
