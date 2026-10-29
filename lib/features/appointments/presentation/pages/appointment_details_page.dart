import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_text.dart';
import '../../../../core/utils/input_masks.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/info_card.dart';
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
        if (widget.professionalView) {
          return _ProfessionalDetails(item: item);
        }
        return _PatientDetails(item: item);
      },
    ),
  );
}

/// Detalhe da consulta na visão do paciente: agendamento, fisioterapeuta e os
/// sintomas que ele informou, no mesmo desenho da visão do fisioterapeuta.
class _PatientDetails extends StatelessWidget {
  const _PatientDetails({required this.item});

  final Appointment item;

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    final info = item.professionalInfo;
    final report = item.observations?.trim() ?? '';

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        InfoCard(
          title: 'Informações do agendamento',
          children: [
            InfoLine(
              icon: Icons.calendar_today_outlined,
              label: 'Data',
              value: weekdayShortMonthDate(item.dateTime),
            ),
            const SizedBox(height: AppSpacing.md),
            InfoLine(
              icon: Icons.schedule_outlined,
              label: 'Horário',
              value: loc.formatTimeOfDay(TimeOfDay.fromDateTime(item.dateTime)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        InfoCard(
          title: 'Informações do fisioterapeuta',
          children: [
            InfoLine(
              icon: Icons.person_outline,
              label: 'Fisioterapeuta',
              value: _orDash(item.professionalName),
            ),
            const SizedBox(height: AppSpacing.md),
            InfoLine(
              icon: Icons.medical_services_outlined,
              label: 'Especialização',
              value: _orDash(item.specialtyName),
            ),
            const SizedBox(height: AppSpacing.md),
            InfoLine(
              icon: Icons.badge_outlined,
              label: 'CREFITO',
              value: _orDash(
                InputMasks.displayCrefito(item.professionalCrefito),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            InfoLine(
              icon: Icons.email_outlined,
              label: 'E-mail para contato',
              value: _orDash(info.email),
            ),
            if (item.professionalBio.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              InfoLine(
                icon: Icons.description_outlined,
                label: 'Descrição',
                value: item.professionalBio,
              ),
            ],
          ],
        ),
        if (report.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          InfoCard(
            title: 'Sintomas',
            children: [
              InfoLine(
                icon: Icons.notes_outlined,
                label: 'Sintomas informados',
                value: report,
              ),
            ],
          ),
        ],
      ],
    );
  }

  static String _orDash(String value) => value.trim().isEmpty ? '—' : value;
}

/// Detalhe da consulta na visão do fisioterapeuta: paciente, horário e relato,
/// em cartões. Não mostra a especialidade do profissional.
class _ProfessionalDetails extends StatelessWidget {
  const _ProfessionalDetails({required this.item});

  final Appointment item;

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    final info = item.patientInfo;
    final cityState = [
      info.cidade.trim(),
      info.estado.trim(),
    ].where((part) => part.isNotEmpty).join(' - ');
    final report = item.observations?.trim() ?? '';

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        InfoCard(
          title: 'Informações do agendamento',
          children: [
            InfoLine(
              icon: Icons.calendar_today_outlined,
              label: 'Data',
              value: weekdayShortMonthDate(item.dateTime),
            ),
            const SizedBox(height: AppSpacing.md),
            InfoLine(
              icon: Icons.schedule_outlined,
              label: 'Horário',
              value: loc.formatTimeOfDay(TimeOfDay.fromDateTime(item.dateTime)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        InfoCard(
          title: 'Informações do paciente',
          children: [
            InfoLine(
              icon: Icons.person_outline,
              label: 'Nome do paciente',
              value: item.patientName.isEmpty ? 'Paciente' : item.patientName,
            ),
            const SizedBox(height: AppSpacing.md),
            InfoLine(
              icon: Icons.email_outlined,
              label: 'E-mail para contato',
              value: info.email.trim().isEmpty ? '—' : info.email,
            ),
            const SizedBox(height: AppSpacing.md),
            InfoLine(
              icon: Icons.location_on_outlined,
              label: 'Cidade e estado',
              value: cityState.isEmpty ? '—' : cityState,
            ),
            const SizedBox(height: AppSpacing.md),
            InfoLine(
              icon: Icons.notes_outlined,
              label: 'Sintomas informados',
              value: report.isEmpty ? 'Nenhum sintoma informado.' : report,
            ),
          ],
        ),
      ],
    );
  }
}
