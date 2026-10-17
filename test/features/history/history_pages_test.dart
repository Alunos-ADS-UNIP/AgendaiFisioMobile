import 'dart:async';

import 'package:agendaifisiomobile/core/theme/app_theme.dart';
import 'package:agendaifisiomobile/core/widgets/app_loading_skeleton.dart';
import 'package:agendaifisiomobile/features/history/domain/history_failure.dart';
import 'package:agendaifisiomobile/features/history/presentation/pages/patient_history_for_professional_page.dart';
import 'package:agendaifisiomobile/features/history/presentation/pages/patient_history_page.dart';
import 'package:agendaifisiomobile/features/history/presentation/widgets/appointment_history_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_history_repository.dart';

Widget _app(Widget home, {double textScale = 1}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: home,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
  );
}

void _useSmallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('mostra carregamento enquanto a primeira página chega', (
    tester,
  ) async {
    final repository = FakeHistoryRepository(entries: [fakeEntry(0)])
      ..gate = Completer<void>();

    await tester.pumpWidget(_app(PatientHistoryPage(repository: repository)));
    expect(find.byType(AppLoadingSkeleton), findsWidgets);

    repository.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(AppLoadingSkeleton), findsNothing);
    expect(find.text('Profissional 0'), findsOneWidget);
  });

  testWidgets('paciente vê data, hora, profissional e status', (tester) async {
    final repository = FakeHistoryRepository(entries: [fakeEntry(0)]);

    await tester.pumpWidget(_app(PatientHistoryPage(repository: repository)));
    await tester.pumpAndSettle();

    expect(find.text('30/09/2026 às 00:00'), findsOneWidget);
    expect(find.text('Profissional 0'), findsOneWidget);
    expect(find.text('Concluído'), findsOneWidget);
    expect(find.text('Você chegou ao fim do histórico.'), findsOneWidget);
    expect(repository.requestedPatientIds, [null]);
  });

  testWidgets('histórico vazio tem mensagem específica', (tester) async {
    await tester.pumpWidget(
      _app(PatientHistoryPage(repository: FakeHistoryRepository())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma consulta realizada'), findsOneWidget);
    expect(find.text('Não foi possível carregar'), findsNothing);
  });

  testWidgets('erro de rede permite tentar novamente', (tester) async {
    final repository = FakeHistoryRepository(
      entries: [fakeEntry(0)],
      failure: HistoryFailure.network,
    );

    await tester.pumpWidget(_app(PatientHistoryPage(repository: repository)));
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível carregar'), findsOneWidget);

    repository.failure = null;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Profissional 0'), findsOneWidget);
  });

  testWidgets('rolagem carrega as próximas páginas sem duplicar', (
    tester,
  ) async {
    final repository = FakeHistoryRepository(
      entries: List.generate(45, fakeEntry),
    );

    await tester.pumpWidget(_app(PatientHistoryPage(repository: repository)));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Você chegou ao fim do histórico.'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(repository.requestedPages, [1, 2, 3]);
    expect(find.text('Profissional 44'), findsOneWidget);
  });

  testWidgets('profissional sem vínculo vê mensagem neutra (403/404)', (
    tester,
  ) async {
    final repository = FakeHistoryRepository(
      failure: HistoryFailure.accessDenied,
    );

    await tester.pumpWidget(
      _app(
        PatientHistoryForProfessionalPage(
          repository: repository,
          patientId: 'paciente-1',
          patientName: 'Carla Souza',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Histórico indisponível'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsNothing);
    expect(find.textContaining('paciente-1'), findsNothing);
    expect(repository.requestedPatientIds, ['paciente-1']);
  });

  testWidgets('profissional autorizado reutiliza o mesmo item visual', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        PatientHistoryForProfessionalPage(
          repository: FakeHistoryRepository(entries: [fakeEntry(0)]),
          patientId: 'paciente-1',
          patientName: 'Carla Souza',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Histórico de Carla Souza'), findsOneWidget);
    expect(find.byType(AppointmentHistoryTile), findsOneWidget);
  });

  for (final textScale in [1.0, 1.5]) {
    testWidgets('cabe em 360 px com texto a ${textScale}x', (tester) async {
      _useSmallPhone(tester);
      final entries = [
        for (var i = 0; i < 5; i++) fakeEntry(i),
        fakeEntry(
          5,
          professionalName:
              'Dra. Maria Fernanda de Albuquerque Cavalcanti Neto',
        ),
      ];

      await tester.pumpWidget(
        _app(
          PatientHistoryPage(
            repository: FakeHistoryRepository(entries: entries),
          ),
          textScale: textScale,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.text('Você chegou ao fim do histórico.'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
