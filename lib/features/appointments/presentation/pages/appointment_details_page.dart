import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/input_masks.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/appointment.dart';
import '../../domain/appointment_repository.dart';

class AppointmentDetailsPage extends StatefulWidget {
  const AppointmentDetailsPage({
    required this.repository,
    required this.appointmentId,
    this.professionalView = false,
    super.key,
  });

  final AppointmentRepository repository;
  final String appointmentId;

  /// Visão do fisioterapeuta: mostra o paciente e o relato do que ele está
  /// sentindo, sem dados pessoais (CPF, telefone, endereço, nascimento).
  final bool professionalView;

  @override
  State<AppointmentDetailsPage> createState() => _AppointmentDetailsPageState();
}

class _AppointmentDetailsPageState extends State<AppointmentDetailsPage> {
  late Future<Appointment> _appointment = widget.repository.fetchAppointment(
    widget.appointmentId,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detalhes')),
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
        final professionalView = widget.professionalView;
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            if (professionalView) ...[
              Text(
                item.patientName.isEmpty ? 'Paciente' : item.patientName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                item.specialtyName.isEmpty
                    ? 'Fisioterapia'
                    : item.specialtyName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
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
            if (professionalView)
              ..._patientSection(context, item)
            else
              ..._professionalSection(context, item),
            // O relato do paciente é informação só para o fisioterapeuta.
            if (professionalView && item.observations?.isNotEmpty == true)
              _DetailRow(
                icon: Icons.notes_outlined,
                label: professionalView
                    ? 'Relato do que está sentindo'
                    : 'Observações',
                value: item.observations!,
              ),
          ],
        );
      },
    ),
  );

  /// Dados do paciente, mostrados ao fisioterapeuta para o contato e o atendimento.
  List<Widget> _patientSection(BuildContext context, Appointment item) {
    final info = item.patientInfo;
    return [
      _SectionTitle(
        'Dados do paciente',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      _DetailRow(
        icon: Icons.email_outlined,
        label: 'E-mail para contato',
        value: _orDash(info.email),
      ),
      _DetailRow(
        icon: Icons.location_on_outlined,
        label: 'Cidade e estado',
        value: _cityState(info),
      ),
    ];
  }

  /// Dados do fisioterapeuta, mostrados ao paciente antes da consulta.
  List<Widget> _professionalSection(BuildContext context, Appointment item) {
    final info = item.professionalInfo;
    return [
      _SectionTitle(
        'Dados do fisioterapeuta',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      _DetailRow(
        icon: Icons.person_outline,
        label: 'Fisioterapeuta',
        value: _orDash(item.professionalName),
      ),
      _DetailRow(
        icon: Icons.medical_services_outlined,
        label: 'Especialização',
        value: _orDash(item.specialtyName),
      ),
      _DetailRow(
        icon: Icons.badge_outlined,
        label: 'CREFITO',
        value: _orDash(InputMasks.displayCrefito(item.professionalCrefito)),
      ),
      _DetailRow(
        icon: Icons.email_outlined,
        label: 'E-mail para contato',
        value: _orDash(info.email),
      ),
      if (item.professionalBio.isNotEmpty)
        _DetailRow(
          icon: Icons.description_outlined,
          label: 'Descrição',
          value: item.professionalBio,
        ),
    ];
  }

  static String _orDash(String value) => value.trim().isEmpty ? '—' : value;

  static String _cityState(ContactInfo info) {
    final parts = [
      info.cidade.trim(),
      info.estado.trim(),
    ].where((part) => part.isNotEmpty).toList();
    return parts.isEmpty ? '—' : parts.join(' - ');
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.style});

  final String title;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xs),
    child: Text(title, style: style),
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
