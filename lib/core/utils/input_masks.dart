import 'package:flutter/services.dart';

/// [TextInputFormatter] simples baseado em máscara, sem depender de pacote
/// externo. '#' no padrão representa um dígito; qualquer outro caractere do
/// padrão é inserido literalmente conforme o usuário digita.
///
/// Importante: isso é só apresentação. O valor com a máscara nunca deve ser
/// enviado para a API — sempre use [InputMasks.digitsOnly] antes de montar o
/// corpo da requisição, porque o backend valida CPF (11 dígitos) e telefone
/// (10 ou 11 dígitos) sem pontuação.
class MaskedInputFormatter extends TextInputFormatter {
  MaskedInputFormatter(this.mask);

  final String mask;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = InputMasks.digitsOnly(newValue.text);
    final buffer = StringBuffer();
    var digitIndex = 0;

    for (final maskChar in mask.split('')) {
      if (digitIndex >= digits.length) break;
      if (maskChar == '#') {
        buffer.write(digits[digitIndex]);
        digitIndex++;
      } else {
        buffer.write(maskChar);
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

abstract final class InputMasks {
  static const cpf = '###.###.###-##';
  static const telefone = '(##) #####-####';
  static const cep = '#####-###';

  static String digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

  static MaskedInputFormatter cpfFormatter() => MaskedInputFormatter(cpf);
  static MaskedInputFormatter telefoneFormatter() => MaskedInputFormatter(telefone);
  static MaskedInputFormatter cepFormatter() => MaskedInputFormatter(cep);

  /// Formata uma string já só com dígitos (como a que vem da API) para
  /// exibição com máscara. Usado para preencher os campos ao abrir a tela
  /// de edição com dados existentes.
  static String applyMask(String mask, String rawDigits) {
    final buffer = StringBuffer();
    var digitIndex = 0;
    for (final maskChar in mask.split('')) {
      if (digitIndex >= rawDigits.length) break;
      if (maskChar == '#') {
        buffer.write(rawDigits[digitIndex]);
        digitIndex++;
      } else {
        buffer.write(maskChar);
      }
    }
    return buffer.toString();
  }
}
