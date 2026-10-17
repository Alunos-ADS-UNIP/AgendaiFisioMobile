import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/appointment_history_entry.dart';

/// Item visual do histórico, usado pelas visões do paciente e do profissional.
/// Apenas apresenta os dados recebidos; não faz chamadas HTTP.
class AppointmentHistoryTile extends StatelessWidget {
  const AppointmentHistoryTile({required this.entry, super.key});

  final AppointmentHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        border: Border.fromBorderSide(BorderSide(color: AppColors.divider)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.event_outlined,
                  size: 20,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    '${formatHistoryDate(entry.dateTime)} às '
                    '${formatHistoryTime(entry.dateTime)}',
                    style: textTheme.titleSmall?.copyWith(
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              entry.professionalName.isEmpty
                  ? 'Profissional não informado'
                  : entry.professionalName,
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            StatusChip(status: entry.status),
          ],
        ),
      ),
    );
  }
}

String formatHistoryDate(DateTime dateTime) {
  final day = dateTime.day.toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  return '$day/$month/${dateTime.year}';
}

String formatHistoryTime(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
