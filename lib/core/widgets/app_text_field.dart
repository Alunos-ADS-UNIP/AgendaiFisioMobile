import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    this.controller,
    this.focusNode,
    this.hint,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.autofillHints,
    // Adicionados pra viabilizar o formulário de perfil do paciente
    // (A-FE-01): máscara de CPF/telefone/CEP e campo de data só leitura que
    // abre o date picker ao tocar. Totalmente opcionais e com os mesmos
    // valores padrão do TextFormField, então nenhum uso existente de
    // AppTextField muda de comportamento.
    this.inputFormatters,
    this.readOnly = false,
    this.onTap,
    this.textCapitalization = TextCapitalization.none,
    this.autovalidateMode,
    this.prefixText,
    this.highlightError = false,
    this.suffixText,
    this.autocorrect = true,
    this.enableSuggestions = true,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hint;
  final String? helperText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool obscureText;
  final bool enabled;
  final int maxLines;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final VoidCallback? onTap;

  /// Ex.: [TextCapitalization.words] em campos de nome, para o teclado já
  /// abrir com a primeira letra maiúscula.
  final TextCapitalization textCapitalization;

  final AutovalidateMode? autovalidateMode;
  final String? prefixText;
  final bool highlightError;
  final String? suffixText;
  final bool autocorrect;
  final bool enableSuggestions;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      obscureText: obscureText,
      enabled: enabled,
      maxLines: obscureText ? 1 : maxLines,
      autofillHints: autofillHints,
      inputFormatters: inputFormatters,
      readOnly: readOnly,
      onTap: onTap,
      textCapitalization: textCapitalization,
      autovalidateMode: autovalidateMode,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      scrollPadding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        prefixText: prefixText,
        suffixIcon: suffixIcon,
        suffixText: suffixText,
        errorText: errorText,
        errorMaxLines: 3,
        enabledBorder: highlightError
            ? const OutlineInputBorder(
                borderRadius: AppRadius.medium,
                borderSide: BorderSide(color: AppColors.error, width: 1.5),
              )
            : null,
        focusedBorder: highlightError
            ? const OutlineInputBorder(
                borderRadius: AppRadius.medium,
                borderSide: BorderSide(color: AppColors.error, width: 2),
              )
            : null,
      ),
    );
  }
}
