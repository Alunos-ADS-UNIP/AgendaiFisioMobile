import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final canPress = onPressed != null && !isLoading;
    final colorScheme = Theme.of(context).colorScheme;
    final child = isLoading
        ? SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(
              // O botao fica desabilitado durante a espera; a cor primaria
              // continua visivel sobre o fundo desabilitado do Material.
              color: colorScheme.primary,
              strokeWidth: 2.4,
              semanticsLabel: 'Carregando',
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon), const SizedBox(width: 8)],
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          );

    final button = FilledButton(
      onPressed: canPress ? onPressed : null,
      style: FilledButton.styleFrom(
        minimumSize: const Size(
          AppSpacing.minimumTouchTarget,
          AppSpacing.minimumTouchTarget,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
      ),
      child: child,
    );

    final accessibleButton = Semantics(
      button: true,
      enabled: canPress,
      liveRegion: isLoading,
      label: isLoading ? '$label. Carregando.' : label,
      child: ExcludeSemantics(child: button),
    );

    return expand
        ? SizedBox(width: double.infinity, child: accessibleButton)
        : accessibleButton;
  }
}
