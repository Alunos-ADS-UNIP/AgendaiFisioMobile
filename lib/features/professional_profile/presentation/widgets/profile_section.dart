import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Seção visual compartilhada pelas telas do perfil profissional.
class ProfileSection extends StatelessWidget {
  const ProfileSection({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppSpacing.sm),
      child,
    ],
  );
}
