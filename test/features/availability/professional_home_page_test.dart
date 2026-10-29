import 'package:agendaifisiomobile/core/models/appointment_status.dart';
import 'package:agendaifisiomobile/core/theme/app_theme.dart';
import 'package:agendaifisiomobile/core/widgets/appointment_card.dart';
import 'package:agendaifisiomobile/development/appointment_preview_repository.dart';
import 'package:agendaifisiomobile/features/appointments/domain/appointment.dart';
import 'package:agendaifisiomobile/features/availability/domain/professional_day_summary.dart';
import 'package:agendaifisiomobile/features/availability/presentation/pages/professional_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Appointment _appt(String id, DateTime date, AppointmentStatus status) =>
    Appointment(
      id: id,
      professionalId: 'p',
      professionalName: 'Dra. Teste',
      dateTime: date,
      status: status,
    );

void main() {
  final now = DateTime(2026, 10, 22, 10);

  group('ProfessionalDaySummary', () {
    test('conta consultas de hoje, exceto canceladas', () {
      final s = ProfessionalDaySummary.from([
        _appt('1', DateTime(2026, 10, 22, 8), AppointmentStatus.completed),
        _appt('2', DateTime(2026, 10, 22, 15), AppointmentStatus.scheduled),
        _appt('3', DateTime(2026, 10, 22, 16), AppointmentStatus.cancelled),
        _appt('4', DateTime(2026, 10, 23, 9), AppointmentStatus.scheduled),
      ], now: now);
      expect(s.todayCount, 2);
    });

    test('próximas: só futuras, agendadas/confirmadas, em ordem', () {
      final s = ProfessionalDaySummary.from([
        _appt('b', DateTime(2026, 10, 24, 9), AppointmentStatus.confirmed),
        _appt('a', DateTime(2026, 10, 22, 15), AppointmentStatus.scheduled),
        _appt('x', DateTime(2026, 10, 22, 8), AppointmentStatus.scheduled),
        _appt('c', DateTime(2026, 10, 25, 9), AppointmentStatus.cancelled),
      ], now: now);
      expect(s.upcoming.map((e) => e.id), ['a', 'b']);
    });

    test('respeita o limite', () {
      final list = [
        for (var i = 1; i <= 8; i++)
          _appt('$i', DateTime(2026, 10, 23, i), AppointmentStatus.scheduled),
      ];
      expect(ProfessionalDaySummary.from(list, now: now).upcoming.length, 5);
    });
  });

  group('ProfessionalHomePage', () {
    Future<void> open(WidgetTester tester, double scale) async {
      tester.view.physicalSize = const Size(360, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: ProfessionalHomePage(
            repository: AppointmentPreviewRepository(),
            professionalName: 'Marina',
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    for (final scale in [1.0, 1.5]) {
      testWidgets('mostra consultas e atalhos em 360 px, texto ${scale}x', (
        tester,
      ) async {
        await open(tester, scale);
        expect(find.byType(AppointmentCard), findsNWidgets(2));
        expect(find.text('Agendar'), findsNothing);
        expect(find.text('Agendar consulta'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
