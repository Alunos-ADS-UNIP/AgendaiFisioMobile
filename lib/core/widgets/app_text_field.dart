import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    this.controller,
    this.hint,
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
    this.autovalidateMode,
    this.prefixText,
    this.highlightError = false,
    this.suffixText,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
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

  /// Quando o validator roda. Use [AutovalidateMode.onUserInteraction] para
  /// mostrar o erro enquanto o usuário digita.
  final AutovalidateMode? autovalidateMode;

  /// Texto fixo antes e depois do valor (ex.: "CREFITO-" e "-F").
  final String? prefixText;

  /// Pinta a borda de vermelho sem o texto de erro padrão, para telas que
  /// mostram o aviso do próprio jeito (ex.: centralizado, sem espaço extra).
  final bool highlightError;
  final String? suffixText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      autovalidateMode: autovalidateMode,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      obscureText: obscureText,
      enabled: enabled,
      maxLines: obscureText ? 1 : maxLines,
      autofillHints: autofillHints,
      inputFormatters: inputFormatters,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        // Com o rótulo sempre acima, os textos fixos ficam sempre visíveis
        // e não disputam espaço com o rótulo.
        floatingLabelBehavior: prefixText != null || suffixText != null
            ? FloatingLabelBehavior.always
            : null,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        suffixIcon: suffixIcon,
        prefixText: prefixText,
        suffixText: suffixText,
        // Desabilitado, o texto fixo fica opaco como o valor do campo.
        prefixStyle: _fixedTextStyle(context),
        suffixStyle: _fixedTextStyle(context),
        errorText: errorText,
        errorMaxLines: 2,
        enabledBorder: highlightError ? _errorBorder(context, 1) : null,
        focusedBorder: highlightError ? _errorBorder(context, 2) : null,
      ),
    );
  }

  TextStyle? _fixedTextStyle(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge;
    if (enabled) return style;
    return style?.copyWith(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
    );
  }

  static InputBorder _errorBorder(BuildContext context, double width) {
    final error = Theme.of(context).colorScheme.error;
    final base = Theme.of(context).inputDecorationTheme.errorBorder;
    return base is OutlineInputBorder
        ? base.copyWith(
            borderSide: BorderSide(color: error, width: width),
          )
        : OutlineInputBorder(
            borderSide: BorderSide(color: error, width: width),
          );
  }
}
