import 'package:flutter/material.dart';

import 'app_primary_button.dart';
import 'app_secondary_button.dart';

Future<bool> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
  String cancelLabel = 'Voltar',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        AppSecondaryButton(
          label: cancelLabel,
          onPressed: () => Navigator.of(dialogContext).pop(false),
          expand: false,
        ),
        AppPrimaryButton(
          label: confirmLabel,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          expand: false,
        ),
      ],
    ),
  );

  return result ?? false;
}
