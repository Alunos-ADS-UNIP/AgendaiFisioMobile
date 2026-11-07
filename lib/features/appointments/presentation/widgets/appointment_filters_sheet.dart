import 'package:flutter/material.dart';

import '../../../../core/models/appointment_status.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_secondary_button.dart';
import '../../domain/appointment_filters.dart';
import '../../domain/appointment_failure.dart';
import '../../domain/appointment_repository.dart';
import '../../domain/professional.dart';

class AppointmentFiltersSheet extends StatefulWidget {
  const AppointmentFiltersSheet({
    required this.repository,
    required this.initialFilters,
    this.professionalView = false,
    super.key,
  });

  final AppointmentRepository repository;
  final AppointmentFilters initialFilters;

  /// Visão do fisioterapeuta: a agenda já é só dele, então não há lista de
  /// profissionais. Os filtros viram atalhos de dia (Hoje, Amanhã) e de status.
  final bool professionalView;

  @override
  State<AppointmentFiltersSheet> createState() =>
      _AppointmentFiltersSheetState();
}

class _AppointmentFiltersSheetState extends State<AppointmentFiltersSheet> {
  static const _supportedStatuses = [
    AppointmentStatus.scheduled,
    AppointmentStatus.confirmed,
    AppointmentStatus.completed,
    AppointmentStatus.cancelled,
  ];

  DateTime? _day;
  String? _professionalId;
  AppointmentStatus? _status;
  List<Professional> _professionals = const [];
  bool _loading = true;
  String? _professionalsError;

  @override
  void initState() {
    super.initState();
    _day = widget.initialFilters.day;
    _professionalId = widget.initialFilters.professionalId;
    _status = widget.initialFilters.status;
    if (widget.professionalView) {
      _loading = false;
    } else {
      _loadProfessionals();
    }
  }

  Future<void> _loadProfessionals() async {
    try {
      final professionals = await widget.repository.fetchProfessionals(
        active: true,
      );
      if (mounted) setState(() => _professionals = professionals);
    } on AppointmentException catch (error) {
      if (mounted) setState(() => _professionalsError = error.userMessage);
    } catch (_) {
      if (mounted) {
        setState(
          () => _professionalsError =
              'Não foi possível carregar os profissionais.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  bool _isSameDay(DateTime? a, DateTime b) =>
      a != null && _dateOnly(a) == _dateOnly(b);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Filtrar agenda',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              if (widget.professionalView) ...[
                _periodChips(context),
                const SizedBox(height: AppSpacing.md),
                _statusChips(context),
              ] else ...[
                AppSecondaryButton(
                  onPressed: _pickDay,
                  icon: Icons.calendar_today_outlined,
                  label: _day == null
                      ? 'Qualquer data'
                      : MaterialLocalizations.of(context)
                            .formatMediumDate(_day!),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String?>(
                  initialValue: _professionalId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Profissional'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todos'),
                    ),
                    if (_professionalId != null &&
                        !_professionals.any(
                          (item) => item.id == _professionalId,
                        ))
                      DropdownMenuItem<String?>(
                        value: _professionalId,
                        child: const Text('Profissional selecionado'),
                      ),
                    ..._professionals.map(
                      (professional) => DropdownMenuItem<String?>(
                        value: professional.id,
                        child: Text(
                          professional.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: _loading
                      ? null
                      : (value) => setState(() => _professionalId = value),
                ),
                if (_loading) const LinearProgressIndicator(),
                if (_professionalsError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      _professionalsError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<AppointmentStatus?>(
                  initialValue: _status,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: [
                    const DropdownMenuItem<AppointmentStatus?>(
                      value: null,
                      child: Text('Todos'),
                    ),
                    ..._supportedStatuses.map(
                      (status) => DropdownMenuItem<AppointmentStatus?>(
                        value: status,
                        child: Text(_statusLabel(status)),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _status = value),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              AppPrimaryButton(
                label: 'Aplicar filtros',
                onPressed: () => Navigator.pop(
                  context,
                  AppointmentFilters(
                    day: _day,
                    professionalId: _professionalId,
                    status: _status,
                  ),
                ),
              ),
              // Na visão do profissional, "Todas" e "Todos" já limpam os filtros.
              if (!widget.professionalView) ...[
                const SizedBox(height: AppSpacing.xs),
                AppSecondaryButton(
                  label: 'Limpar filtros',
                  onPressed: () =>
                      Navigator.pop(context, const AppointmentFilters()),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Atalhos de dia: Hoje, Amanhã, data escolhida e Todas as datas.
  Widget _periodChips(BuildContext context) {
    final today = _dateOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    final isToday = _isSameDay(_day, today);
    final isTomorrow = _isSameDay(_day, tomorrow);
    final isCustom = _day != null && !isToday && !isTomorrow;
    return _chipSection(context, 'Período', [
      ChoiceChip(
        label: const Text('Hoje'),
        selected: isToday,
        onSelected: (_) => setState(() => _day = today),
      ),
      ChoiceChip(
        label: const Text('Amanhã'),
        selected: isTomorrow,
        onSelected: (_) => setState(() => _day = tomorrow),
      ),
      ChoiceChip(
        avatar: const Icon(Icons.calendar_today_outlined, size: 18),
        label: Text(
          isCustom
              ? MaterialLocalizations.of(context).formatMediumDate(_day!)
              : 'Escolher data',
        ),
        selected: isCustom,
        onSelected: (_) => _pickDay(),
      ),
      ChoiceChip(
        label: const Text('Todas'),
        selected: _day == null,
        onSelected: (_) => setState(() => _day = null),
      ),
    ]);
  }

  Widget _statusChips(BuildContext context) => _chipSection(context, 'Status', [
    ChoiceChip(
      label: const Text('Todos'),
      selected: _status == null,
      onSelected: (_) => setState(() => _status = null),
    ),
    for (final status in _supportedStatuses)
      ChoiceChip(
        label: Text(_statusLabel(status)),
        selected: _status == status,
        onSelected: (_) => setState(() => _status = status),
      ),
  ]);

  Widget _chipSection(BuildContext context, String title, List<Widget> chips) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: chips,
          ),
        ],
      );

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _day ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
      helpText: 'Filtrar por data',
    );
    if (picked != null && mounted) setState(() => _day = picked);
  }

  String _statusLabel(AppointmentStatus status) => switch (status) {
    AppointmentStatus.scheduled => 'Agendado',
    AppointmentStatus.confirmed => 'Confirmado',
    AppointmentStatus.inProgress => 'Em andamento',
    AppointmentStatus.completed => 'Concluído',
    AppointmentStatus.cancelled => 'Cancelado',
    AppointmentStatus.missed => 'Falta',
  };
}
