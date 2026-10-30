import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

const _monthNames = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

const _weekdayLetters = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

/// Calendário mensal para escolher o dia da consulta. Dias antes de hoje ficam
/// desabilitados; as setas trocam de mês até [monthsAhead] meses à frente.
class MonthCalendarPicker extends StatefulWidget {
  const MonthCalendarPicker({
    required this.selected,
    required this.onChanged,
    this.monthsAhead = 12,
    super.key,
  });

  final DateTime? selected;
  final ValueChanged<DateTime> onChanged;
  final int monthsAhead;

  @override
  State<MonthCalendarPicker> createState() => _MonthCalendarPickerState();
}

class _MonthCalendarPickerState extends State<MonthCalendarPicker> {
  late DateTime _visibleMonth = _startOfMonth(
    widget.selected ?? DateTime.now(),
  );

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime _startOfMonth(DateTime date) =>
      DateTime(date.year, date.month);

  bool get _canGoBack => _visibleMonth.isAfter(_startOfMonth(_today));

  bool get _canGoForward {
    final last = DateTime(_today.year, _today.month + widget.monthsAhead);
    return _visibleMonth.isBefore(_startOfMonth(last));
  }

  void _move(int months) => setState(
    () => _visibleMonth = _startOfMonth(
      DateTime(_visibleMonth.year, _visibleMonth.month + months),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final year = _visibleMonth.year;
    final month = _visibleMonth.month;
    final firstWeekday = DateTime(year, month).weekday % 7;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final cells = firstWeekday + daysInMonth;
    final rows = (cells / 7).ceil();
    final today = _today;

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Mês anterior',
              onPressed: _canGoBack ? () => _move(-1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                '${_monthNames[month - 1]} de $year',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: 'Próximo mês',
              onPressed: _canGoForward ? () => _move(1) : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        Row(
          children: [
            for (final letter in _weekdayLetters)
              Expanded(
                child: Text(
                  letter,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        for (var row = 0; row < rows; row++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: _cell(
                    row * 7 + col - firstWeekday,
                    year,
                    month,
                    today,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _cell(int index, int year, int month, DateTime today) {
    final day = index + 1;
    final inMonth = index >= 0 && day <= DateTime(year, month + 1, 0).day;
    if (!inMonth) return const SizedBox(height: 44);

    final date = DateTime(year, month, day);
    final isPast = date.isBefore(today);
    final isSelected =
        widget.selected != null &&
        widget.selected!.year == year &&
        widget.selected!.month == month &&
        widget.selected!.day == day;

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Semantics(
        button: true,
        enabled: !isPast,
        selected: isSelected,
        label: '$day de ${_monthNames[month - 1]}',
        child: InkWell(
          key: ValueKey('dia-$year-$month-$day'),
          borderRadius: AppRadius.pill,
          onTap: isPast ? null : () => widget.onChanged(date),
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : null,
              shape: BoxShape.circle,
              border: isSelected
                  ? null
                  : (date == today
                        ? Border.all(color: AppColors.primary)
                        : null),
            ),
            child: Text(
              '$day',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isSelected
                    ? Colors.white
                    : (isPast ? AppColors.textDisabled : AppColors.textPrimary),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
