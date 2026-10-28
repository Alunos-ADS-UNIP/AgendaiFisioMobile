import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loading_skeleton.dart';
import '../../../../core/widgets/error_state.dart';
import '../../domain/availability_failure.dart';
import '../../domain/availability_models.dart';
import '../../domain/availability_repository.dart';
import '../controllers/available_slots_controller.dart';

/// Horários de um dia da agenda do profissional. Cada horário mostra o estado
/// em texto e ícone, não só em cor: livre, selecionado, ocupado ou desabilitado.
class AvailableSlotsPage extends StatefulWidget {
  const AvailableSlotsPage({
    required this.repository,
    required this.professionalId,
    super.key,
  });

  final AvailabilityRepository repository;
  final String professionalId;

  @override
  State<AvailableSlotsPage> createState() => _AvailableSlotsPageState();
}

class _AvailableSlotsPageState extends State<AvailableSlotsPage> {
  late final AvailableSlotsController _controller = AvailableSlotsController(
    repository: widget.repository,
    professionalId: widget.professionalId,
  )..load();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static String _dateLabel(DateTime date) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${WeekDay.fromDate(date).label}, ${two(date.day)}/${two(date.month)}';
  }

  static (String, IconData) _stateInfo(SlotState state) => switch (state) {
    SlotState.free => ('Livre', Icons.radio_button_unchecked),
    SlotState.selected => ('Selecionado', Icons.check_circle),
    SlotState.busy => ('Ocupado', Icons.event_busy_outlined),
    SlotState.disabled => ('Indisponível', Icons.block),
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Horários do dia')),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _dayBar(context),
            const SizedBox(height: AppSpacing.md),
            _body(context),
          ],
        ),
      ),
    ),
  );

  Widget _dayBar(BuildContext context) => Row(
    children: [
      IconButton(
        tooltip: 'Dia anterior',
        onPressed: _controller.canGoBack && !_controller.isLoading
            ? () => _controller.changeDay(-1)
            : null,
        icon: const Icon(Icons.chevron_left),
      ),
      Expanded(
        child: Text(
          _dateLabel(_controller.date),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      IconButton(
        tooltip: 'Próximo dia',
        onPressed: _controller.isLoading
            ? null
            : () => _controller.changeDay(1),
        icon: const Icon(Icons.chevron_right),
      ),
    ],
  );

  Widget _body(BuildContext context) {
    final c = _controller;
    if (c.isLoading) {
      return const AppLoadingSkeleton(lines: 4);
    }
    if (c.failure != null) {
      return ErrorState(
        message: switch (c.failure!) {
          AvailabilityFailure.network =>
            'Verifique sua conexão e tente novamente.',
          AvailabilityFailure.unauthorized =>
            'Sua sessão expirou. Entre novamente.',
          _ => 'Não foi possível carregar os horários.',
        },
        onRetry: c.load,
      );
    }
    final selected = c.selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          selected == null
              ? 'Toque em um horário livre para selecioná-lo.'
              : 'Selecionado: ${AvailableSlot(start: selected, state: SlotState.selected).label}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final slot in c.slots) _slotTile(context, slot),
          ],
        ),
      ],
    );
  }

  Widget _slotTile(BuildContext context, AvailableSlot slot) {
    final state = _controller.isSelected(slot) ? SlotState.selected : slot.state;
    final (text, icon) = _stateInfo(state);
    final scheme = Theme.of(context).colorScheme;
    final background = switch (state) {
      SlotState.selected => AppColors.primaryLight,
      SlotState.busy => AppColors.warningLight,
      SlotState.disabled => AppColors.surfaceVariant,
      _ => AppColors.surface,
    };
    final foreground = state == SlotState.disabled
        ? AppColors.textDisabled
        : AppColors.textPrimary;
    return Semantics(
      button: slot.isSelectable,
      label: '${slot.label}, $text',
      child: InkWell(
        borderRadius: AppRadius.medium,
        onTap: slot.isSelectable ? () => _controller.select(slot) : null,
        child: Container(
          width: 104,
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: background,
            borderRadius: AppRadius.medium,
            border: Border.all(
              color: state == SlotState.selected
                  ? scheme.primary
                  : AppColors.divider,
              width: state == SlotState.selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                slot.label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: foreground),
                  const SizedBox(width: 4),
                  Text(
                    text,
                    style: TextStyle(fontSize: 12, color: foreground),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
