import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_secondary_button.dart';
import '../../domain/availability_failure.dart';
import '../../domain/availability_models.dart';
import '../../domain/availability_repository.dart';
import '../controllers/weekly_schedule_form_controller.dart';

/// Edição da grade semanal: ativar/desativar cada dia, escolher início e fim
/// dos turnos e adicionar turnos. Turnos inválidos ou sobrepostos são
/// apontados na hora e impedem o envio.
///
/// Fecha com `true` quando o repositório confirma o salvamento.
class WeeklyScheduleFormPage extends StatefulWidget {
  const WeeklyScheduleFormPage({
    required this.repository,
    required this.initial,
    super.key,
  });

  final AvailabilityRepository repository;
  final WeeklySchedule initial;

  @override
  State<WeeklyScheduleFormPage> createState() => _WeeklyScheduleFormPageState();
}

class _WeeklyScheduleFormPageState extends State<WeeklyScheduleFormPage> {
  late final WeeklyScheduleFormController _controller =
      WeeklyScheduleFormController(
        repository: widget.repository,
        initial: widget.initial,
      );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final saved = await _controller.save();
    if (saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grade de horários salva.')),
      );
      Navigator.of(context).pop(true);
    }
  }

  Future<TimeOfDayValue?> _pickTime(TimeOfDayValue initial) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    return picked == null ? null : TimeOfDayValue(picked.hour, picked.minute);
  }

  Future<void> _editStart(WeekDay day, int index, TimeRange shift) async {
    final value = await _pickTime(shift.start);
    if (value == null) return;
    _controller.updateShift(
      day,
      index,
      TimeRange(start: value, end: shift.end),
    );
  }

  Future<void> _editEnd(WeekDay day, int index, TimeRange shift) async {
    final value = await _pickTime(shift.end);
    if (value == null) return;
    _controller.updateShift(
      day,
      index,
      TimeRange(start: shift.start, end: value),
    );
  }

  static String _problemText(DayProblem problem) => switch (problem) {
    DayProblem.noShifts => 'Adicione pelo menos um turno ou desative o dia.',
    DayProblem.invalidRange => 'O horário final deve ser depois do inicial.',
    DayProblem.overlap => 'Os turnos não podem se sobrepor.',
  };

  static String _failureText(AvailabilityFailure failure) => switch (failure) {
    AvailabilityFailure.unavailable =>
      'Não foi possível salvar: esta função ainda não está disponível no sistema.',
    AvailabilityFailure.network =>
      'Não foi possível salvar. Confira sua conexão e tente novamente.',
    AvailabilityFailure.unauthorized => 'Sua sessão expirou. Entre novamente.',
    AvailabilityFailure.invalidData =>
      'Os horários informados não foram aceitos. Revise e tente novamente.',
    AvailabilityFailure.unknown =>
      'Não foi possível salvar. Tente novamente em instantes.',
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Configurar grade')),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              'Marque os dias em que você atende e defina os horários de cada turno.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            for (final day in _controller.schedule.days)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _dayCard(context, day),
              ),
            if (_controller.attemptedSave && !_controller.isValid) ...[
              const SizedBox(height: AppSpacing.xs),
              _message(
                context,
                'Corrija os horários destacados antes de salvar.',
              ),
            ],
            if (_controller.failure != null) ...[
              const SizedBox(height: AppSpacing.xs),
              _message(context, _failureText(_controller.failure!)),
            ],
            const SizedBox(height: AppSpacing.md),
            AppPrimaryButton(
              label: 'Salvar grade',
              icon: Icons.check,
              isLoading: _controller.isSaving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _message(BuildContext context, String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        Icons.error_outline,
        size: 20,
        color: Theme.of(context).colorScheme.error,
      ),
      const SizedBox(width: AppSpacing.xs),
      Expanded(
        child: Text(
          text,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    ],
  );

  Widget _dayCard(BuildContext context, DayAvailability day) {
    final problems = _controller.problemsOf(day.day);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: day.enabled ? AppColors.primaryLight : AppColors.surface,
        borderRadius: AppRadius.large,
        border: Border.all(
          color: problems.isEmpty
              ? AppColors.divider
              : Theme.of(context).colorScheme.error,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                day.day.label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text(day.enabled ? 'Atende neste dia' : 'Sem atendimento'),
              value: day.enabled,
              onChanged: (value) =>
                  _controller.setDayEnabled(day.day, value),
            ),
            if (day.enabled) ...[
              for (var i = 0; i < day.shifts.length; i++)
                _shiftRow(context, day.day, i, day.shifts[i]),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _controller.addShift(day.day),
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar turno'),
                ),
              ),
              for (final problem in problems)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: _message(context, _problemText(problem)),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _shiftRow(
    BuildContext context,
    WeekDay day,
    int index,
    TimeRange shift,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              AppSecondaryButton(
                label: 'Início ${shift.start.label}',
                icon: Icons.schedule,
                expand: false,
                onPressed: () => _editStart(day, index, shift),
              ),
              AppSecondaryButton(
                label: 'Fim ${shift.end.label}',
                icon: Icons.schedule,
                expand: false,
                onPressed: () => _editEnd(day, index, shift),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Remover turno',
          onPressed: () => _controller.removeShift(day, index),
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    ),
  );
}
