import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loading_skeleton.dart';
import '../../../../core/widgets/app_secondary_button.dart';
import '../../../../core/widgets/appointment_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../appointments/domain/appointment.dart';
import '../../../appointments/domain/appointment_repository.dart';
import '../../../appointments/presentation/pages/appointments_page.dart';
import '../../domain/professional_day_summary.dart';

/// Tela inicial do fisioterapeuta: resumo do dia, próximas consultas e atalhos.
///
/// Usa apenas a rota de agenda que já existe (GET /api/agendamento), pelo
/// [AppointmentRepository]. Atalhos cujas telas ainda não existem recebem
/// `null` e aparecem desativados com o texto "em breve".
class ProfessionalHomePage extends StatefulWidget {
  const ProfessionalHomePage({
    required this.repository,
    this.professionalName,
    this.onOpenPatients,
    this.onOpenSchedule,
    this.onOpenProfile,
    this.onLogout,
    this.now,
    super.key,
  });

  final AppointmentRepository repository;
  final String? professionalName;
  final VoidCallback? onOpenPatients;
  final VoidCallback? onOpenSchedule;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onLogout;

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
    appBar: AppBar(
      title: const Text('AgendaiFisio'),
      actions: [
        if (widget.onLogout != null)
          IconButton(
            onPressed: widget.onLogout,
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
          ),
      ],
    ),
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
            const SizedBox(height: AppSpacing.lg),
            Text('Atalhos', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            AppSecondaryButton(
              onPressed: _openAgenda,
              icon: Icons.calendar_month_outlined,
              label: 'Agenda',
            ),
            const SizedBox(height: AppSpacing.sm),
            _shortcut(
              label: 'Pacientes',
              icon: Icons.groups_outlined,
              onPressed: widget.onOpenPatients,
            ),
            const SizedBox(height: AppSpacing.sm),
            _shortcut(
              label: 'Grade de horários',
              icon: Icons.schedule_outlined,
              onPressed: widget.onOpenSchedule,
            ),
            const SizedBox(height: AppSpacing.sm),
            _shortcut(
              label: 'Perfil',
              icon: Icons.person_outline,
              onPressed: widget.onOpenProfile,
            ),
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
          message: 'Quando houver consultas agendadas, elas aparecem aqui.',
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
              onTap: _openAgenda,
            ),
          ),
    ];
  }

  /// Atalho ainda sem tela: desativado e com texto explícito, nunca só cor.
  Widget _shortcut({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) => AppSecondaryButton(
    onPressed: onPressed,
    icon: icon,
    label: onPressed == null ? '$label (em breve)' : label,
  );

  Future<void> _openAgenda() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AppointmentsPage(
          repository: widget.repository,
          title: 'Agenda',
        ),
      ),
    );
    if (mounted) _refresh();
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
