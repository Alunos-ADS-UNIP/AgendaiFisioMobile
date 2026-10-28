import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/appointment_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../domain/appointment.dart';
import '../../domain/appointment_failure.dart';
import '../../domain/appointment_filters.dart';
import '../../domain/appointment_repository.dart';
import '../controllers/appointments_controller.dart';
import '../widgets/appointment_filters_sheet.dart';
import 'appointment_details_page.dart';
import 'new_appointment_page.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({
    required this.repository,
    this.initialFilters = const AppointmentFilters(),
    this.title = 'Minha agenda',
    this.professionalView = false,
    super.key,
  });

  final AppointmentRepository repository;
  final AppointmentFilters initialFilters;
  final String title;

  /// Visão do fisioterapeuta: só consulta a agenda. Agendar é exclusivo do
  /// paciente, então o botão e a ação de criar não aparecem, e o cartão mostra
  /// o nome do paciente.
  final bool professionalView;

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  late final AppointmentsController _controller = AppointmentsController(
    repository: widget.repository,
  );

  @override
  void initState() {
    super.initState();
    _controller.load(filters: widget.initialFilters);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
      actions: [
        IconButton(
          tooltip: 'Filtrar agenda',
          onPressed: _openFilters,
          icon: const Icon(Icons.filter_alt_outlined),
        ),
      ],
    ),
    floatingActionButton: widget.professionalView
        ? null
        : FloatingActionButton.extended(
            onPressed: _newAppointment,
            icon: const Icon(Icons.add),
            label: const Text('Agendar'),
          ),
    body: ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoading && _controller.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_controller.failure != null && _controller.items.isEmpty) {
          return ErrorState(
            message: _failureMessage(_controller.failure!),
            onRetry: _controller.load,
          );
        }
        if (_controller.isEmpty) {
          return EmptyState(
            title: 'Nenhum agendamento encontrado',
            message: _controller.filters.isEmpty
                ? (widget.professionalView
                      ? 'Quando um paciente agendar uma consulta, ela aparecerá aqui.'
                      : 'Quando você marcar uma consulta, ela aparecerá aqui.')
                : 'Tente alterar ou limpar os filtros da agenda.',
            icon: Icons.calendar_month_outlined,
            actionLabel: _controller.filters.isEmpty
                ? (widget.professionalView ? null : 'Criar agendamento')
                : 'Limpar filtros',
            onAction: _controller.filters.isEmpty
                ? (widget.professionalView ? null : _newAppointment)
                : () => _controller.load(filters: const AppointmentFilters()),
          );
        }
        return RefreshIndicator(
          onRefresh: _controller.load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              100,
            ),
            children: [
              if (_controller.isLoading) const LinearProgressIndicator(),
              ..._controller.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppointmentCard(
                    dateLabel: _dateLabel(context, item.dateTime),
                    timeLabel: _timeLabel(context, item.dateTime),
                    personName:
                        widget.professionalView && item.patientName.isNotEmpty
                        ? item.patientName
                        : item.professionalName,
                    specialtyName: item.specialtyName.isEmpty
                        ? 'Fisioterapia'
                        : item.specialtyName,
                    status: item.status,
                    onTap: () => _openDetails(item),
                  ),
                ),
              ),
              if (_controller.totalPages > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Página anterior',
                      onPressed: _controller.canGoBack
                          ? () => _controller.goToPage(_controller.page - 1)
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text(
                      'Página ${_controller.page} de ${_controller.totalPages}',
                    ),
                    IconButton(
                      tooltip: 'Próxima página',
                      onPressed: _controller.canGoForward
                          ? () => _controller.goToPage(_controller.page + 1)
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    ),
  );

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<AppointmentFilters>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AppointmentFiltersSheet(
        repository: widget.repository,
        initialFilters: _controller.filters,
        professionalView: widget.professionalView,
      ),
    );
    if (result != null) await _controller.load(filters: result);
  }

  Future<void> _newAppointment() async {
    final created = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (_) => NewAppointmentPage(repository: widget.repository),
      ),
    );
    if (created == true) await _controller.load();
  }

  Future<void> _openDetails(Appointment item) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AppointmentDetailsPage(
          repository: widget.repository,
          appointmentId: item.id,
          professionalView: widget.professionalView,
        ),
      ),
    );
    if (mounted) await _controller.load();
  }

  String _dateLabel(BuildContext context, DateTime date) =>
      MaterialLocalizations.of(context).formatCompactDate(date).toUpperCase();

  String _timeLabel(BuildContext context, DateTime date) =>
      MaterialLocalizations.of(context)
          .formatTimeOfDay(TimeOfDay.fromDateTime(date));

  String _failureMessage(AppointmentFailure error) => switch (error) {
    AppointmentFailure.unauthorized => 'Sua sessão expirou. Entre novamente.',
    AppointmentFailure.network => 'Confira sua conexão e tente novamente.',
    AppointmentFailure.notFound => 'Nenhum agendamento foi encontrado.',
    AppointmentFailure.conflict =>
      'Esse horário acabou de ser reservado. Escolha outro.',
    AppointmentFailure.invalid => 'Confira os dados e tente novamente.',
    AppointmentFailure.incompleteProfile =>
      'Complete seu cadastro antes de agendar.',
    AppointmentFailure.unexpected =>
      'Não foi possível carregar a agenda. Tente novamente.',
  };
}
