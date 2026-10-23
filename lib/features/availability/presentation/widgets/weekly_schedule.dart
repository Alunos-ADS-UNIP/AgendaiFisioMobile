import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/availability_models.dart';

/// Visão semanal somente leitura: um cartão por dia, de segunda a domingo.
/// Sem HTTP, reutilizável. Estado nunca depende só de cor: há ícone e texto.
class WeeklyScheduleView extends StatelessWidget {
  const WeeklyScheduleView({required this.schedule, super.key});

  final WeeklySchedule schedule;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final day in schedule.days)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _DayCard(day: day),
        ),
    ],
  );
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day});

  final DayAvailability day;

  @override
  Widget build(BuildContext context) {
    final active = day.enabled && day.shifts.isNotEmpty;
    final summary = active
        ? 'Atendimento: ${day.shifts.map((s) => s.label).join(', ')}'
        : 'Sem atendimento';
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      label: '${day.day.label}. $summary',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: active ? AppColors.primaryLight : AppColors.surface,
            borderRadius: AppRadius.large,
            border: Border.all(color: AppColors.divider),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  active ? Icons.check_circle_outline : Icons.block_outlined,
                  color: active
                      ? AppColors.primaryDark
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(day.day.label, style: textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.xxs),
                      if (active)
                        for (final shift in day.shifts)
                          Text(shift.label, style: textTheme.bodyMedium)
                      else
                        Text(
                          'Sem atendimento',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
