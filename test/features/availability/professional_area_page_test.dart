import 'package:agendaifisiomobile/core/theme/app_theme.dart';
import 'package:agendaifisiomobile/development/appointment_preview_repository.dart';
import 'package:agendaifisiomobile/features/availability/domain/availability_repository.dart';
import 'package:agendaifisiomobile/features/availability/presentation/pages/professional_area_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ProfessionalAreaPage(
          repository: AppointmentPreviewRepository(),
          availabilityRepository: const UnavailableAvailabilityRepository(),
          professionalId: 'prof-teste',
          professionalName: 'Marina',
          profileBuilder: (_) => const Scaffold(body: Text('Tela de perfil')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('menu do fisioterapeuta não tem a opção Agendar', (tester) async {
    await open(tester);
    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Agenda'), findsOneWidget);
    expect(find.text('Grade'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Agendar'), findsNothing);
  });

  testWidgets('navega entre as abas sem botão de agendar', (tester) async {
    await open(tester);
    await tester.tap(find.text('Agenda'));
    await tester.pumpAndSettle();
    expect(find.byType(FloatingActionButton), findsNothing);

    await tester.tap(find.text('Grade'));
    await tester.pumpAndSettle();
    expect(find.text('Grade ainda não disponível'), findsOneWidget);

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Tela de perfil'), findsOneWidget);
  });
}
