import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loading_skeleton.dart';
import '../../../../core/widgets/appointment_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../appointments/domain/appointment.dart';
import '../../../appointments/domain/appointment_repository.dart';
import '../../domain/professional_day_summary.dart';

/// Início do fisioterapeuta: resumo do dia e próximas consultas.
///
/// Usa apenas a rota de agenda que já existe (GET /api/agendamento), pelo
/// [AppointmentRepository]. A navegação entre áreas fica no menu inferior da
/// [ProfessionalAreaPage]; tocar numa consulta chama [onOpenAgenda].
/// O fisioterapeuta não agenda consultas: esta tela só consulta.
class ProfessionalHomePage extends StatefulWidget {
  const ProfessionalHomePage({
    required this.repository,
    this.professionalName,
    this.onOpenAgenda,
    this.now,
    super.key,
  });

  final AppointmentRepository repository;
  final String? professionalName;
  final VoidCallback? onOpenAgenda;

  /// Relógio injetável para testes. Em produção fica nulo (usa DateTime.now()).
  final DateTime Function()? now;

  @override
  State<ProfessionalHomePage> createState() => _ProfessionalHomePageState();
}

class _ProfessionalHomePageState extends State<ProfessionalHomePage> {
  late Future<List<Appointment>> _appointments = widget.repository
      .fetchAppointments();

  DateTime get _now => widget.now?.call() ?? DateTime.now();

  Future<void> _refresh() async {
    final future = widget.repository.fetchAppointments();
    setState(() => _appointments = future);
    try {
      await future;
    } catch (_) {
      // O erro já é mostrado pelo FutureBuilder.
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AgendaiFisio')),
    body: RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<Appointment>>(
        future: _appointments,
        builder: (context, snapshot) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              'Olá${widget.professionalName?.isNotEmpty == true ? ', ${widget.professionalName}' : ''}!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Veja o resumo do seu dia e as próximas consultas.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            ..._content(context, snapshot),
          ],
        ),
      ),
    ),
  );

  List<Widget> _content(
    BuildContext context,
    AsyncSnapshot<List<Appointment>> snapshot,
  ) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const [AppLoadingSkeleton(lines: 3)];
    }
    if (snapshot.hasError) {
      return [
        ErrorState(
          message: 'Não foi possível carregar suas consultas.',
          onRetry: _refresh,
        ),
      ];
    }

    final summary = ProfessionalDaySummary.from(
      snapshot.data ?? const <Appointment>[],
      now: _now,
    );
    final loc = MaterialLocalizations.of(context);

    return [
      _TodayCard(count: summary.todayCount),
      const SizedBox(height: AppSpacing.lg),
      Text(
        'Próximas consultas',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: AppSpacing.sm),
      if (summary.upcoming.isEmpty)
        const EmptyState(
          title: 'Nenhuma consulta próxima',
          message: 'Quando um paciente agendar uma consulta, ela aparece aqui.',
          icon: Icons.event_available_outlined,
        )
      else
        for (final item in summary.upcoming)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppointmentCard(
              dateLabel: loc.formatCompactDate(item.dateTime).toUpperCase(),
              timeLabel: loc.formatTimeOfDay(
                TimeOfDay.fromDateTime(item.dateTime),
              ),
              personName: item.patientName.isEmpty
                  ? 'Paciente'
                  : item.patientName,
              specialtyName: item.specialtyName.isEmpty
                  ? 'Fisioterapia'
                  : item.specialtyName,
              status: item.status,
              onTap: widget.onOpenAgenda,
            ),
          ),
    ];
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final text = switch (count) {
      0 => 'Nenhuma consulta hoje',
      1 => '1 consulta hoje',
      _ => '$count consultas hoje',
    };
    return Semantics(
      container: true,
      label: 'Resumo do dia: $text',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const Icon(Icons.today_outlined, color: AppColors.primaryDark),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryDark,
                    ),
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
