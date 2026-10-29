import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';

/// Botão da feature que permite quebra de linha com texto ampliado.
class SpecialtyPrimaryButton extends StatelessWidget {
  const SpecialtyPrimaryButton({
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
    final content = isLoading
        ? const SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          )
        : Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 2,
            children: [
              if (icon != null) Icon(icon),
              Text(label, textAlign: TextAlign.center),
            ],
          );

    final button = FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
      ),
      child: content,
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
