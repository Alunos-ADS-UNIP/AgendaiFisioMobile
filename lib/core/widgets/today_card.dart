import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Resumo do dia: quantas consultas acontecem hoje.
class TodayCard extends StatelessWidget {
  const TodayCard({required this.count, super.key});

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
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: AppColors.primaryDark),
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
