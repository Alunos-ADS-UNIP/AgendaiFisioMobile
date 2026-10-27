import 'package:agendaifisiomobile/core/theme/app_theme.dart';
import 'package:agendaifisiomobile/development/appointment_preview_repository.dart';
import 'package:agendaifisiomobile/features/appointments/presentation/pages/appointments_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> open(WidgetTester tester, {required bool professionalView}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AppointmentsPage(
          repository: AppointmentPreviewRepository(),
          professionalView: professionalView,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('fisioterapeuta não vê o botão de agendar', (tester) async {
    await open(tester, professionalView: true);
    expect(find.text('Agendar'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('paciente continua vendo o botão de agendar', (tester) async {
    await open(tester, professionalView: false);
    expect(find.text('Agendar'), findsOneWidget);
  });
}
