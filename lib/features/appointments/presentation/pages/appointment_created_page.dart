import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_secondary_button.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/appointment.dart';
import '../../domain/appointment_repository.dart';
import 'appointment_details_page.dart';

class AppointmentCreatedPage extends StatelessWidget {
  const AppointmentCreatedPage({
    required this.repository,
    required this.appointment,
    super.key,
  });

  final AppointmentRepository repository;
  final Appointment appointment;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Agendamento confirmado'),
      leading: IconButton(
        tooltip: 'Voltar à agenda',
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context, true),
      ),
    ),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 68, color: Colors.green),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Agendamento criado',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              appointment.professionalName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
              if (appointment.specialtyName.isNotEmpty)
                Text(appointment.specialtyName),
            Text(
              MaterialLocalizations.of(context)
                  .formatMediumDate(appointment.dateTime),
            ),
            Text(
              MaterialLocalizations.of(
                context,
              ).formatTimeOfDay(TimeOfDay.fromDateTime(appointment.dateTime)),
            ),
            const SizedBox(height: AppSpacing.sm),
            StatusChip(status: appointment.status),
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(
              label: 'Ver detalhes',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AppointmentDetailsPage(
                    repository: repository,
                    appointmentId: appointment.id,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppSecondaryButton(
              label: 'Voltar à agenda',
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ),
    ),
  );
}
