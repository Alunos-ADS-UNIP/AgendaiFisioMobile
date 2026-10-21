import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../domain/auth_session.dart';

class RoleHomePage extends StatelessWidget {
  const RoleHomePage({required this.user, required this.onLogout, super.key});

  final AuthenticatedUser user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('AgendaiFisio'),
      actions: [
        IconButton(
          onPressed: onLogout,
          tooltip: 'Sair',
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(
                      Icons.verified_user_outlined,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Login realizado',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${user.role.label} • ${user.email}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Sua sessão está ativa. A área deste perfil será conectada nas próximas entregas.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppPrimaryButton(
                    label: 'Sair da conta',
                    icon: Icons.logout,
                    onPressed: onLogout,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
