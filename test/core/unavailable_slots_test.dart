import 'package:agendaifisiomobile/core/widgets/month_calendar_picker.dart';
import 'package:agendaifisiomobile/core/widgets/time_slot_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  final now = DateTime.now();
  final todayKey = ValueKey('dia-${now.year}-${now.month}-${now.day}');

  testWidgets('dia indisponível no calendário não pode ser escolhido', (
    tester,
  ) async {
    DateTime? picked;
    await tester.pumpWidget(
      _wrap(
        MonthCalendarPicker(
          selected: null,
          isDayUnavailable: (_) => true,
          onChanged: (day) => picked = day,
        ),
      ),
    );
    await tester.tap(find.byKey(todayKey));
    expect(picked, isNull);
  });

  testWidgets('dia livre no calendário continua selecionável', (tester) async {
    DateTime? picked;
    await tester.pumpWidget(
      _wrap(
        MonthCalendarPicker(
          selected: null,
          isDayUnavailable: (_) => false,
          onChanged: (day) => picked = day,
        ),
      ),
    );
    await tester.tap(find.byKey(todayKey));
    expect(picked, DateTime(now.year, now.month, now.day));
  });

  testWidgets('horário indisponível fica opaco e não é escolhido', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        TimeSlotPickerSheet(
          initial: const TimeOfDay(hour: 9, minute: 0),
          isUnavailable: (time) => time.hour == 9 || time.hour == 10,
        ),
      ),
    );
    // O inicial está bloqueado: começa no primeiro horário livre.
    expect(find.text('Selecionado: 06:00'), findsOneWidget);
    double opacityOf(String label) => tester
        .widget<Opacity>(
          find.ancestor(of: find.text(label), matching: find.byType(Opacity)),
        )
        .opacity;
    expect(opacityOf('09:00'), lessThan(1));
    expect(opacityOf('11:00'), 1);

    await tester.tap(find.text('10:00'));
    await tester.pump();
    expect(find.text('Selecionado: 06:00'), findsOneWidget);

    await tester.tap(find.text('11:00'));
    await tester.pump();
    expect(find.text('Selecionado: 11:00'), findsOneWidget);
  });

  testWidgets('sem horário livre o botão Confirmar fica desativado', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(TimeSlotPickerSheet(isUnavailable: (_) => true)),
    );
    expect(find.text('Nenhum horário selecionado'), findsOneWidget);
    final confirm = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Confirmar'),
    );
    expect(confirm.onPressed, isNull);
  });
}
