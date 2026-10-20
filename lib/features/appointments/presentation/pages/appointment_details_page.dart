import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/appointment.dart';
import '../../domain/appointment_repository.dart';

class AppointmentDetailsPage extends StatefulWidget {
  const AppointmentDetailsPage({
    required this.repository,
    required this.appointmentId,
    super.key,
  });

  final AppointmentRepository repository;
  final String appointmentId;

  @override
  State<AppointmentDetailsPage> createState() => _AppointmentDetailsPageState();
}

class _AppointmentDetailsPageState extends State<AppointmentDetailsPage> {
  late Future<Appointment> _appointment = widget.repository.fetchAppointment(
    widget.appointmentId,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detalhes do agendamento')),
    body: FutureBuilder<Appointment>(
      future: _appointment,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return ErrorState(
            message: 'Esse agendamento não está disponível ou houve uma falha de conexão.',
            onRetry: () => setState(
              () => _appointment = widget.repository.fetchAppointment(
                widget.appointmentId,
              ),
            ),
          );
        }
        final item = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              item.professionalName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              item.specialtyName.isEmpty ? 'Fisioterapia' : item.specialtyName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            StatusChip(status: item.status),
            const SizedBox(height: AppSpacing.lg),
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Data',
              value: MaterialLocalizations.of(context)
                  .formatMediumDate(item.dateTime),
            ),
            _DetailRow(
              icon: Icons.schedule_outlined,
              label: 'Horário',
              value: MaterialLocalizations.of(context)
                  .formatTimeOfDay(TimeOfDay.fromDateTime(item.dateTime)),
            ),
            if (item.observations?.isNotEmpty == true)
              _DetailRow(
                icon: Icons.notes_outlined,
                label: 'Observações',
                value: item.observations!,
              ),
          ],
        );
      },
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    ),
  );
}
