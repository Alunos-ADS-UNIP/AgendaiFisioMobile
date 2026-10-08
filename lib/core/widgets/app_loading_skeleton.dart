import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class AppLoadingSkeleton extends StatelessWidget {
  const AppLoadingSkeleton({this.lines = 3, super.key});

  final int lines;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Carregando conteúdo',
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.large,
          border: Border.fromBorderSide(BorderSide(color: AppColors.divider)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              lines,
              (index) => Padding(
                padding: EdgeInsets.only(
                  bottom: index == lines - 1 ? 0 : AppSpacing.sm,
                ),
                child: FractionallySizedBox(
                  widthFactor: index == lines - 1 ? 0.56 : 1,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: AppRadius.small,
                    ),
                    child: SizedBox(height: 16),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
