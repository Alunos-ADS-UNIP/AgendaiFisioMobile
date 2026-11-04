import 'package:agendaifisiomobile/features/availability/domain/availability_models.dart';
import 'package:agendaifisiomobile/features/availability/domain/availability_repository.dart';
import 'package:agendaifisiomobile/features/availability/presentation/pages/professional_availability_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _EmptyRepository implements AvailabilityRepository {
  @override
  Future<WeeklySchedule> fetchWeeklySchedule() async => WeeklySchedule.empty();

  @override
  Future<void> saveWeeklySchedule(WeeklySchedule schedule) async {}

  @override
  Future<List<AvailableSlot>> fetchSlots({
    required String professionalId,
    required DateTime date,
  }) async => const [];
}

void main() {
  testWidgets('botão de configurar horários fica fixo embaixo da tela', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProfessionalAvailabilityPage(repository: _EmptyRepository()),
      ),
    );
    await tester.pumpAndSettle();

    final button = find.text('Configurar horários');
    expect(button, findsOneWidget);
    // Nada no topo: o botão saiu da barra superior.
    expect(find.byTooltip('Editar grade'), findsNothing);
    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(tester.getCenter(button).dy, greaterThan(screenHeight / 2));
    final primary = tester.widget<FilledButton>(
      find.ancestor(of: button, matching: find.byType(FilledButton)),
    );
    expect(primary.onPressed, isNotNull);
  });
}
