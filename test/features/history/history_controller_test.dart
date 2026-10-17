import 'dart:async';

import 'package:agendaifisiomobile/features/history/domain/history_failure.dart';
import 'package:agendaifisiomobile/features/history/presentation/controllers/history_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_history_repository.dart';

void main() {
  HistoryController controllerFor(
    FakeHistoryRepository repository, {
    int pageSize = 2,
  }) {
    return HistoryController(
      pageSize: pageSize,
      loadPage: (page, size) =>
          repository.fetchMyHistory(page: page, pageSize: size),
    );
  }

  test('pagina mantendo a ordem da API e para no fim', () async {
    final entries = List.generate(5, fakeEntry);
    final repository = FakeHistoryRepository(entries: entries);
    final controller = controllerFor(repository);

    await controller.loadFirstPage();
    await controller.loadNextPage();
    await controller.loadNextPage();

    expect(
      controller.items.map((e) => e.appointmentId),
      entries.map((e) => e.appointmentId),
    );
    expect(controller.hasReachedEnd, isTrue);

    await controller.loadNextPage();
    expect(repository.requestedPages, [1, 2, 3]);
  });

  test('não duplica itens repetidos entre páginas', () async {
    final entries = [
      fakeEntry(0),
      fakeEntry(1),
      fakeEntry(1), // a API repetiu o mesmo agendamento na página seguinte
      fakeEntry(2),
    ];
    final controller = controllerFor(FakeHistoryRepository(entries: entries));

    await controller.loadFirstPage();
    await controller.loadNextPage();

    expect(controller.items.map((e) => e.appointmentId), [
      'agendamento-0',
      'agendamento-1',
      'agendamento-2',
    ]);
  });

  test('não dispara a mesma página duas vezes em paralelo', () async {
    final repository = FakeHistoryRepository(
      entries: List.generate(6, fakeEntry),
    );
    final controller = controllerFor(repository);
    await controller.loadFirstPage();

    repository.gate = Completer<void>();
    final first = controller.loadNextPage();
    final second = controller.loadNextPage();
    expect(controller.isLoadingMore, isTrue);
    repository.gate!.complete();
    await Future.wait([first, second]);

    expect(repository.requestedPages, [1, 2]);
  });

  test('histórico vazio fica no estado vazio, não em erro', () async {
    final controller = controllerFor(FakeHistoryRepository());

    await controller.loadFirstPage();

    expect(controller.isEmpty, isTrue);
    expect(controller.failure, isNull);
    expect(controller.hasReachedEnd, isTrue);
  });

  test('falha inicial expõe o erro e permite tentar de novo', () async {
    final repository = FakeHistoryRepository(
      entries: [fakeEntry(0)],
      failure: HistoryFailure.network,
    );
    final controller = controllerFor(repository);

    await controller.loadFirstPage();
    expect(controller.failure, HistoryFailure.network);
    expect(controller.items, isEmpty);

    repository.failure = null;
    await controller.loadFirstPage();
    expect(controller.failure, isNull);
    expect(controller.items, hasLength(1));
  });

  test('falha na próxima página mantém os itens e permite retentar', () async {
    final repository = FakeHistoryRepository(
      entries: List.generate(4, fakeEntry),
    );
    final controller = controllerFor(repository);
    await controller.loadFirstPage();

    repository.failure = HistoryFailure.network;
    await controller.loadNextPage();
    expect(controller.loadMoreFailure, HistoryFailure.network);
    expect(controller.items, hasLength(2));

    await controller.loadNextPage();
    expect(repository.requestedPages, [1, 2], reason: 'só retenta por ação');

    repository.failure = null;
    await controller.retryLoadMore();
    expect(controller.items, hasLength(4));
    expect(controller.loadMoreFailure, isNull);
  });

  test('recarregar descarta resposta antiga em andamento', () async {
    final repository = FakeHistoryRepository(
      entries: List.generate(4, fakeEntry),
    );
    final controller = controllerFor(repository);
    await controller.loadFirstPage();

    repository.gate = Completer<void>();
    final stale = controller.loadNextPage();
    final refresh = controller.loadFirstPage();
    repository.gate!.complete();
    await Future.wait([stale, refresh]);

    expect(controller.items.map((e) => e.appointmentId), [
      'agendamento-0',
      'agendamento-1',
    ]);
  });
}
