import 'package:flutter/material.dart';

import '../models/appointment_status.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({required this.status, super.key});

  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    final style = _statusStyle(status);

    return Semantics(
      label: 'Status ${style.label}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: AppRadius.pill,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(style.icon, color: style.foreground, size: 16),
              const SizedBox(width: 6),
              Text(
                style.label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: style.foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

({String label, IconData icon, Color background, Color foreground})
_statusStyle(AppointmentStatus status) {
  return switch (status) {
    AppointmentStatus.scheduled => (
      label: 'Agendado',
      icon: Icons.calendar_month_outlined,
      background: AppColors.secondaryLight,
      foreground: const Color(0xFF1E40AF),
    ),
    AppointmentStatus.confirmed => (
      label: 'Confirmado',
      icon: Icons.check_circle_outline,
      background: AppColors.successLight,
      foreground: const Color(0xFF166534),
    ),
    AppointmentStatus.inProgress => (
      label: 'Em andamento',
      icon: Icons.play_circle_outline,
      background: AppColors.warningLight,
      foreground: const Color(0xFF92400E),
    ),
    AppointmentStatus.completed => (
      label: 'Concluído',
      icon: Icons.task_alt,
      background: AppColors.primaryLight,
      foreground: AppColors.primaryDark,
    ),
    AppointmentStatus.cancelled => (
      label: 'Cancelado',
      icon: Icons.cancel_outlined,
      background: AppColors.errorLight,
      foreground: const Color(0xFF991B1B),
    ),
    AppointmentStatus.missed => (
      label: 'Falta',
      icon: Icons.person_off_outlined,
      background: AppColors.divider,
      foreground: const Color(0xFF334155),
    ),
  };
}
