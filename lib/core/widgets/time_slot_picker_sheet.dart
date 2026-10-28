import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Seletor de horário único do app: uma grade de horários fixos em que o
/// usuário toca no horário desejado. Substitui o relógio redondo do sistema.
///
/// Devolve um [TimeOfDay] ao confirmar, ou null se fechar sem escolher.
/// Intervalo padrão de 30 min, entre [startHour] e [endHour].
class TimeSlotPickerSheet extends StatefulWidget {
  const TimeSlotPickerSheet({
    this.initial,
    this.title = 'Escolha o horário',
    this.startHour = 6,
    this.endHour = 22,
    super.key,
  });

  final TimeOfDay? initial;
  final String title;
  final int startHour;
  final int endHour;

  /// Abre o seletor como folha inferior e devolve o horário escolhido.
  static Future<TimeOfDay?> show(
    BuildContext context, {
    TimeOfDay? initial,
    String title = 'Escolha o horário',
  }) => showModalBottomSheet<TimeOfDay>(
    context: context,
    isScrollControlled: true,
    builder: (_) => TimeSlotPickerSheet(initial: initial, title: title),
  );

  @override
  State<TimeSlotPickerSheet> createState() => _TimeSlotPickerSheetState();
}

class _TimeSlotPickerSheetState extends State<TimeSlotPickerSheet> {
  static const _stepMinutes = 30;
  late int _selected = _initialMinutes();

  int _initialMinutes() {
    final initial = widget.initial;
    if (initial == null) return widget.startHour * 60;
    return initial.hour * 60 + initial.minute;
  }

  List<int> get _slots => [
    for (var m = widget.startHour * 60; m <= widget.endHour * 60; m += _stepMinutes)
      m,
  ];

  static String _label(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Selecionado: ${_label(_selected)}',
              style: textTheme.titleMedium?.copyWith(color: AppColors.primaryDark),
            ),
            const SizedBox(height: AppSpacing.md),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 4,
                mainAxisSpacing: AppSpacing.xs,
                crossAxisSpacing: AppSpacing.xs,
                childAspectRatio: 2.2,
                children: [
                  for (final minutes in _slots)
                    _SlotChip(
                      label: _label(minutes),
                      selected: minutes == _selected,
                      onTap: () => setState(() => _selected = minutes),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(48, 52),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.medium,
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(
                      TimeOfDay(hour: _selected ~/ 60, minute: _selected % 60),
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(48, 52),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.medium,
                      ),
                    ),
                    child: const Text('Confirmar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: 'Horário $label',
    child: Material(
      color: selected ? AppColors.primary : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.medium,
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.divider,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.medium,
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    ),
  );
}
