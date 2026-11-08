import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/models/appointment_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_text.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/appointment.dart';
import '../../domain/appointment_failure.dart';
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
  bool _isCancelling = false;
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
          return _ProfessionalDetails(
            item: item,
            isCancelling: _isCancelling,
            onCancel: _canCancel(item) ? () => _cancel(item) : null,
          );
        }
        return _PatientDetails(
          item: item,
          isCancelling: _isCancelling,
          onCancel: _canCancel(item) ? () => _cancel(item) : null,
        );
      },
    ),
  );

  bool _canCancel(Appointment item) =>
      item.status != AppointmentStatus.cancelled &&
      item.status != AppointmentStatus.completed;

  Future<void> _cancel(Appointment item) async {
    if (_isCancelling) return;
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Cancelar agendamento?',
      message: 'O horário será liberado e o agendamento continuará no histórico como cancelado.',
      confirmLabel: 'Sim, cancelar',
    );
    if (!confirmed || !mounted) return;

    setState(() => _isCancelling = true);
    try {
      final cancelled = await widget.repository.cancelAppointment(item.id);
      if (!mounted) return;
      setState(() {
        _isCancelling = false;
        _appointment = Future.value(item.copyWith(status: cancelled.status));
      });
      AppFeedback.showSuccess(context, 'Agendamento cancelado com sucesso.');
    } on AppointmentException catch (error) {
      if (!mounted) return;
      setState(() => _isCancelling = false);
      AppFeedback.showError(context, _cancelErrorMessage(error));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCancelling = false);
      AppFeedback.showError(
        context,
        'Não foi possível cancelar o agendamento. Tente novamente.',
      );
    }
  }

  String _cancelErrorMessage(AppointmentException error) =>
      error.message ??
      switch (error.failure) {
        AppointmentFailure.conflict =>
          'Esse agendamento já foi cancelado ou não pode mais ser cancelado.',
        AppointmentFailure.notFound =>
          'O agendamento não foi encontrado ou não pertence a você.',
        _ => error.userMessage,
      };
}

/// Detalhe da consulta na visão do paciente: agendamento, fisioterapeuta e os
/// sintomas que ele informou, no mesmo desenho da visão do fisioterapeuta.
class _PatientDetails extends StatelessWidget {
  const _PatientDetails({
    required this.item,
    required this.isCancelling,
    required this.onCancel,
  });

  final Appointment item;
  final bool isCancelling;
  final VoidCallback? onCancel;

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
            StatusChip(status: item.status),
            const SizedBox(height: AppSpacing.md),
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
              value: _orDash(item.professionalCrefito),
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
        if (onCancel != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _CancelAppointmentButton(
            isLoading: isCancelling,
            onPressed: onCancel,
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
  const _ProfessionalDetails({
    required this.item,
    required this.isCancelling,
    required this.onCancel,
  });

  final Appointment item;
  final bool isCancelling;
  final VoidCallback? onCancel;

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
            StatusChip(status: item.status),
            const SizedBox(height: AppSpacing.md),
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
        if (onCancel != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _CancelAppointmentButton(
            isLoading: isCancelling,
            onPressed: onCancel,
          ),
        ],
      ],
    );
  }
}

class _CancelAppointmentButton extends StatelessWidget {
  const _CancelAppointmentButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      key: const ValueKey('cancel-appointment-button'),
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: const BorderSide(color: AppColors.error),
        minimumSize: const Size(48, 48),
      ),
      child: isLoading
          ? const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            )
          : const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_busy_outlined),
                SizedBox(width: AppSpacing.sm),
                Text('Cancelar agendamento'),
              ],
            ),
    ),
  );
}
