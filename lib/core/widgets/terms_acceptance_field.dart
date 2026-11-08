import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Campo obrigatório compartilhado pelos cadastros de paciente e profissional.
/// O valor começa desmarcado para que o aceite seja sempre explícito.
class TermsAcceptanceField extends FormField<bool> {
  TermsAcceptanceField({required super.enabled, super.key})
    : super(
        initialValue: false,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (value) => value == true
            ? null
            : 'Aceite os Termos de Uso e a Política de Privacidade.',
        builder: (field) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              key: const ValueKey('terms-acceptance-checkbox'),
              value: field.value ?? false,
              onChanged: enabled ? (value) => field.didChange(value) : null,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Li e aceito os Termos de Uso e a Política de Privacidade.',
              ),
            ),
            if (field.errorText != null)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.md),
                child: Text(
                  field.errorText!,
                  style: TextStyle(
                    color: Theme.of(field.context).colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      );
}
