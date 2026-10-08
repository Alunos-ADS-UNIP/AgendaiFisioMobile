import 'package:agendaifisiomobile/app/app.dart';
import 'package:agendaifisiomobile/core/models/appointment_status.dart';
import 'package:agendaifisiomobile/core/theme/app_theme.dart';
import 'package:agendaifisiomobile/core/widgets/appointment_card.dart';
import 'package:agendaifisiomobile/core/widgets/professional_card.dart';
import 'package:agendaifisiomobile/core/widgets/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exibe o catálogo dos componentes compartilhados', (
    tester,
  ) async {
    await tester.pumpWidget(const AgendaiFisioApp());

    expect(find.text('AgendaiFisio - Componentes'), findsOneWidget);
    expect(find.text('Base compartilhada'), findsOneWidget);
    expect(find.text('Ação principal'), findsOneWidget);
  });

  testWidgets('StatusChip apresenta texto e ícone do status', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: StatusChip(status: AppointmentStatus.scheduled),
        ),
      ),
    );

    expect(find.text('Agendado'), findsOneWidget);
    expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
  });

  testWidgets('catálogo não apresenta overflow em 360 px', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const AgendaiFisioApp());
    expect(tester.takeException(), isNull, reason: 'overflow no início');

    for (var index = 0; index < 10; index++) {
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pump();
      final exception = tester.takeException();
      expect(exception, isNull, reason: 'overflow após rolagem $index');
    }

    expect(find.text('Estado de erro'), findsOneWidget);
  });

  testWidgets('AppointmentCard cabe em 360 px', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: AppointmentCard(
              dateLabel: '18 OUT',
              timeLabel: '14:30',
              personName: 'Dra. Marina Lopes',
              specialtyName: 'Fisioterapia esportiva',
              status: AppointmentStatus.confirmed,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('ProfessionalCard cabe em 360 px', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: ProfessionalCard(
              name: 'Dra. Marina Lopes',
              specialty: 'Fisioterapia esportiva',
              crefito: 'CREFITO 123456-F',
              isActive: true,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
