import 'dart:io';
import 'dart:ui' as ui;

import 'package:agendaifisiomobile/core/theme/app_theme.dart';
import 'package:agendaifisiomobile/core/widgets/appointment_card.dart';
import 'package:agendaifisiomobile/development/appointment_preview_repository.dart';
import 'package:agendaifisiomobile/features/appointments/presentation/pages/appointment_created_page.dart';
import 'package:agendaifisiomobile/features/appointments/presentation/pages/appointment_details_page.dart';
import 'package:agendaifisiomobile/features/appointments/presentation/pages/appointments_page.dart';
import 'package:agendaifisiomobile/features/appointments/presentation/pages/patient_area_page.dart';
import 'package:agendaifisiomobile/features/appointments/presentation/pages/patient_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

final _boundaryKey = GlobalKey();

void main() {
  setUpAll(() async {
    final loader = FontLoader('Inter');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/inter/Inter-$weight.ttf'));
    }
    await loader.load();
    final icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  for (final scale in [1.0, 1.5]) {
    _designTest('agenda e filtros em 360 px, texto ${scale}x', (tester) async {
      final repository = AppointmentPreviewRepository();
      await _open(tester, AppointmentsPage(repository: repository), scale);
      expect(find.byType(AppointmentCard), findsNWidgets(2));
      _noOverflow(tester);
      await _capture(tester, 'agenda-$scale');
      await tester.tap(find.byTooltip('Filtrar agenda'));
      await tester.pumpAndSettle();
      _noOverflow(tester);
      expect(find.text('Aplicar filtros'), findsOneWidget);
      await _capture(tester, 'filtros-$scale');
      await tester.ensureVisible(find.text('Limpar filtros'));
      await tester.tap(find.text('Limpar filtros'));
      await tester.pumpAndSettle();
      expect(find.byType(AppointmentCard), findsNWidgets(2));
      _noOverflow(tester);
    });

    _designTest(
      'início, detalhe, confirmação e navegação em 360 px, texto ${scale}x',
      (tester) async {
        final repository = AppointmentPreviewRepository();
        final item = (await repository.fetchAppointments()).first;
        for (final screen in <String, Widget>{
          'inicio': PatientHomePage(repository: repository, patientName: 'Ana'),
          'detalhe': AppointmentDetailsPage(
            repository: repository,
            appointmentId: item.id,
          ),
          'sucesso': AppointmentCreatedPage(
            repository: repository,
            appointment: item,
          ),
          'navegacao': PatientAreaPage(repository: repository, initialIndex: 2),
        }.entries) {
          await _open(tester, screen.value, scale);
          _noOverflow(tester);
          await _capture(tester, '${screen.key}-$scale');
        }
        for (final label in ['Início', 'Agendar', 'Agenda', 'Perfil']) {
          expect(find.text(label), findsWidgets);
        }
        await tester.tap(find.text('Perfil'));
        await tester.pumpAndSettle();
        expect(find.text('Perfil ainda não conectado'), findsOneWidget);
        _noOverflow(tester);
      },
    );

    _designTest(
      'fluxo completo cria e atualiza agenda em 360 px, texto ${scale}x',
      (tester) async {
        final repository = AppointmentPreviewRepository();
        await _open(tester, AppointmentsPage(repository: repository), scale);
        await tester.tap(find.text('Agendar'));
        await tester.pumpAndSettle();
        _noOverflow(tester);
        await _capture(tester, 'especialidade-$scale');
        await tester.tap(find.text('Selecionar especialidade'));
        await tester.pumpAndSettle();
        _noOverflow(tester);
        await _capture(tester, 'seletor-$scale');
        await tester.tap(find.text('Fisioterapia esportiva').last);
        await tester.pumpAndSettle();
        _noOverflow(tester);
        await tester.tap(find.text('Dra. Marina Lopes'));
        await tester.pumpAndSettle();
        await _capture(tester, 'profissional-$scale');
        await tester.ensureVisible(find.text('Escolher data e horário'));
        await tester.tap(find.text('Escolher data e horário'));
        await tester.pumpAndSettle();
        _noOverflow(tester);
        await tester.ensureVisible(find.text('Selecionar data'));
        await tester.tap(find.text('Selecionar data'));
        await tester.pumpAndSettle();
        _noOverflow(tester);
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Selecionar horário'));
        await tester.tap(find.text('Selecionar horário'));
        await tester.pumpAndSettle();
        _noOverflow(tester);
        await tester.tap(find.text('Confirmar'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField),
          'Observação de demonstração.',
        );
        await tester.pumpAndSettle();
        await _capture(tester, 'revisao-$scale');
        await tester.ensureVisible(find.text('Confirmar agendamento'));
        await tester.tap(find.text('Confirmar agendamento'));
        await tester.pumpAndSettle();
        _noOverflow(tester);
        expect(find.text('Agendamento criado'), findsOneWidget);
        await tester.ensureVisible(find.text('Voltar à agenda'));
        await tester.tap(find.text('Voltar à agenda'));
        await tester.pumpAndSettle();
        final items = await repository.fetchAppointments();
        expect(items, hasLength(3));
        final created = items.singleWhere(
          (item) => item.observations == 'Observação de demonstração.',
        );
        final dateLabel = MaterialLocalizations.of(
          tester.element(find.byType(AppointmentsPage)),
        ).formatCompactDate(created.dateTime).toUpperCase();
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is AppointmentCard && widget.dateLabel == dateLabel,
          ),
          findsOneWidget,
        );
        _noOverflow(tester);
      },
    );
  }
}

Future<void> _open(WidgetTester tester, Widget home, double scale) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    RepaintBoundary(
      key: _boundaryKey,
      child: MaterialApp(
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _noOverflow(WidgetTester tester) => expect(tester.takeException(), isNull);

Future<void> _capture(WidgetTester tester, String name) async {
  final directory = Platform.environment['AGENDA_SCREENSHOTS_DIR'];
  if (directory == null) return;
  final boundary =
      _boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(directory).create(recursive: true);
    await File('$directory/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void _designTest(String description, Future<void> Function(WidgetTester) body) {
  testWidgets(description, (tester) async {
    final previous = debugDisableShadows;
    debugDisableShadows = false;
    try {
      await body(tester);
    } finally {
      debugDisableShadows = previous;
    }
  });
}
