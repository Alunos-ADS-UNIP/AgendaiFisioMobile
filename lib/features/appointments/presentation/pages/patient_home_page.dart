import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/appointment_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../domain/appointment.dart';
import '../../domain/appointment_repository.dart';
import 'appointments_page.dart';
import 'new_appointment_page.dart';
import '../../../history/domain/history_repository.dart' as history;
import '../../../history/presentation/pages/patient_history_page.dart';

class PatientHomePage extends StatefulWidget {
  const PatientHomePage({
    required this.repository,
    this.historyRepository,
    this.patientName,
    super.key,
  });

  final AppointmentRepository repository;
  final history.HistoryRepository? historyRepository;
  final String? patientName;

  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  late Future<List<Appointment>> _appointments = widget.repository
      .fetchAppointments();

  Future<void> _refresh() async {
    setState(() => _appointments = widget.repository.fetchAppointments());
    await _appointments;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AgendaiFisio')),
    body: RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<Appointment>>(
        future: _appointments,
        builder: (context, snapshot) {
          final futureAppointments =
              (snapshot.data ?? const <Appointment>[])
                  .where((item) => item.dateTime.isAfter(DateTime.now()))
                  .toList()
                ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                'Olá${widget.patientName?.isNotEmpty == true ? ', ${widget.patientName}' : ''}!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Cuide da sua saúde com a sua próxima consulta.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (snapshot.connectionState != ConnectionState.done)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (snapshot.hasError)
                ErrorState(
                  message: 'Não foi possível carregar sua próxima consulta.',
                  onRetry: _refresh,
                )
              else if (futureAppointments.isEmpty)
                const EmptyState(
                  title: 'Você ainda não tem uma próxima consulta',
                  message:
                      'Agende com um profissional para ver sua consulta aqui.',
                  icon: Icons.event_available_outlined,
                )
              else ...[
                Text(
                  'Próxima consulta',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppointmentCard(
                  dateLabel: MaterialLocalizations.of(context)
                      .formatShortDate(futureAppointments.first.dateTime)
                      .toUpperCase(),
                  timeLabel: MaterialLocalizations.of(context).formatTimeOfDay(
                    TimeOfDay.fromDateTime(futureAppointments.first.dateTime),
                  ),
                  personName: futureAppointments.first.professionalName,
                  specialtyName: futureAppointments.first.specialtyName.isEmpty
                      ? 'Fisioterapia'
                      : futureAppointments.first.specialtyName,
                  status: futureAppointments.first.status,
                  onTap: () => _openAgenda(),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: _newAppointment,
                icon: const Icon(Icons.add),
                label: const Text('Agendar consulta'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: _openAgenda,
                icon: const Icon(Icons.calendar_month_outlined),
                label: const Text('Minha agenda'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: _openHistory,
                icon: const Icon(Icons.history),
                label: const Text('Histórico de consultas'),
              ),
            ],
          );
        },
      ),
    ),
  );

  Future<void> _openAgenda() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AppointmentsPage(repository: widget.repository),
      ),
    );
    if (mounted) _refresh();
  }

  Future<void> _newAppointment() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => NewAppointmentPage(repository: widget.repository),
      ),
    );
    if (created == true && mounted) _refresh();
  }

  Future<void> _openHistory() async {
    final historyRepository = widget.historyRepository;
    if (historyRepository == null) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => AppointmentsPage(
            repository: widget.repository,
            title: 'Histórico de consultas',
          ),
        ),
      );
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PatientHistoryPage(repository: historyRepository),
      ),
    );
  }
}
