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
  static const telefoneFixo = '(##) ####-####';
  static const cep = '#####-###';

  static String digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

  static MaskedInputFormatter cpfFormatter() => MaskedInputFormatter(cpf);
  static MaskedInputFormatter telefoneFormatter() =>
      MaskedInputFormatter(telefone);
  static TextInputFormatter telefoneFlexFormatter() =>
      TextInputFormatter.withFunction((oldValue, newValue) {
        final formatted = applyTelefoneMask(newValue.text);
        return TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      });

  static String applyTelefoneMask(String value) {
    final digits = digitsOnly(value);
    return applyMask(digits.length <= 10 ? telefoneFixo : telefone, digits);
  }

  static MaskedInputFormatter cepFormatter() => MaskedInputFormatter(cep);

  /// Data digitada no formato DD/MM/AAAA, sem seletor de calendário.
  static MaskedInputFormatter dataFormatter() => MaskedInputFormatter(data);

  static const data = '##/##/####';
  static final _dataPattern = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$');

  /// Converte DD/MM/AAAA em data. Devolve null quando o texto está incompleto
  /// ou não existe no calendário (ex.: 31/02).
  static DateTime? parseDate(String value) {
    final match = _dataPattern.firstMatch(value.trim());
    if (match == null) return null;
    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final year = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  /// CREFITO no formato convencional: número de 3 a 6 dígitos, hífen e a letra
  /// da região (ex.: 12345-F). O formatador aceita o que for digitado e monta o
  /// padrão: até 6 dígitos e, depois deles, a letra da região.
  static TextInputFormatter crefitoFormatter() =>
      TextInputFormatter.withFunction((oldValue, newValue) {
        final formatted = formatCrefito(newValue.text);
        return TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      });

  static final _crefitoPattern = RegExp(r'^\d{3,6}-[A-Z]$');
  static final _crefitoLoosePattern = RegExp(r'^(\d{3,6})\s*-?\s*([A-Za-z])$');

  static bool isCrefito(String value) =>
      _crefitoPattern.hasMatch(value.trim().toUpperCase());

  static String formatCrefito(String value) {
    final upper = value.toUpperCase();
    final allDigits = digitsOnly(upper);
    final number = allDigits.length > 6 ? allDigits.substring(0, 6) : allDigits;
    final letter = RegExp('[A-Z]').stringMatch(upper);
    if (number.isEmpty) return '';
    return letter == null ? number : '$number-$letter';
  }

  /// Mostra um CREFITO já salvo: no padrão quando for reconhecível (ex.:
  /// "12345F" vira "12345-F"); valores antigos e fora do padrão ficam como estão.
  static String displayCrefito(String raw) {
    final trimmed = raw.trim();
    final match = _crefitoLoosePattern.firstMatch(trimmed);
    if (match == null) return trimmed;
    return '${match.group(1)}-${match.group(2)!.toUpperCase()}';
  }

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
