import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class ProfessionalCard extends StatelessWidget {
  const ProfessionalCard({
    required this.name,
    required this.specialty,
    required this.crefito,
    required this.isActive,
    this.isSelected = false,
    this.onTap,
    super.key,
  });

  final String name;
  final String specialty;
  final String crefito;
  final bool isActive;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: isSelected,
    child: Material(
      color: isSelected ? AppColors.primaryLight : AppColors.surface,
      elevation: 1,
      shadowColor: AppColors.divider,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.large,
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.divider,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.large,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.secondaryLight,
                child: Icon(
                  isSelected ? Icons.check : Icons.person_outline,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      specialty,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                    Text(
                      crefito,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.successLight
                            : AppColors.surfaceVariant,
                        borderRadius: AppRadius.pill,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isActive
                                  ? Icons.check_circle_outline
                                  : Icons.pause_circle_outline,
                              size: 16,
                              color: isActive
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: AppSpacing.xxs),
                            Flexible(
                              child: Text(
                                isActive ? 'Ativo' : 'Inativo',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: isActive
                                          ? AppColors.success
                                          : AppColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
