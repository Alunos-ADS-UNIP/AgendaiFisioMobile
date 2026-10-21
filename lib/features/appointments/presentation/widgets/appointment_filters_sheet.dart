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
    super.key,
  });

  final AppointmentRepository repository;
  final AppointmentFilters initialFilters;

  @override
  State<AppointmentFiltersSheet> createState() =>
      _AppointmentFiltersSheetState();
}

class _AppointmentFiltersSheetState extends State<AppointmentFiltersSheet> {
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
    _loadProfessionals();
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
              AppSecondaryButton(
                onPressed: _pickDay,
                icon: Icons.calendar_today_outlined,
                label: _day == null
                    ? 'Qualquer data'
                    : MaterialLocalizations.of(context).formatMediumDate(_day!),
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
                      !_professionals.any((item) => item.id == _professionalId))
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
                  ...AppointmentStatus.values.map(
                    (status) => DropdownMenuItem<AppointmentStatus?>(
                      value: status,
                      child: Text(_statusLabel(status)),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _status = value),
              ),
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
              const SizedBox(height: AppSpacing.xs),
              AppSecondaryButton(
                label: 'Limpar filtros',
                onPressed: () =>
                    Navigator.pop(context, const AppointmentFilters()),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
