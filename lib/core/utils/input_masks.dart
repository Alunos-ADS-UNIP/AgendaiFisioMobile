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

  /// CREFITO no formato CREFITO-{região}/{número}-F (ex.: CREFITO-3/123456-F).
  /// A região (1 a 20) e o número (3 a 6 dígitos) são digitados em campos
  /// separados, nessa ordem, e montados aqui.
  static final _crefitoPattern = RegExp(r'^CREFITO-(\d{1,2})/(\d{3,6})-F$');

  /// Região do CREFITO: até 2 dígitos, sem zero à esquerda ("09" vira "9").
  static TextInputFormatter crefitoRegionFormatter() =>
      TextInputFormatter.withFunction((oldValue, newValue) {
        var digits = digitsOnly(newValue.text).replaceFirst(RegExp(r'^0+'), '');
        if (digits.length > 2) digits = digits.substring(0, 2);
        return TextEditingValue(
          text: digits,
          selection: TextSelection.collapsed(offset: digits.length),
        );
      });

  /// Número do CREFITO (até 6 dígitos) com "-F" colado logo depois dele.
  /// O "-F" aparece mesmo sem dígitos, com o cursor sempre antes dele; apagar
  /// o "-F" apaga o último dígito.
  static TextInputFormatter crefitoNumberFormatter() =>
      TextInputFormatter.withFunction((oldValue, newValue) {
        var digits = digitsOnly(newValue.text);
        if (digits.length > 6) digits = digits.substring(0, 6);
        final oldDigits = digitsOnly(oldValue.text);
        if (digits == oldDigits &&
            newValue.text.length < oldValue.text.length &&
            digits.isNotEmpty) {
          digits = digits.substring(0, digits.length - 1);
        }
        final text = '$digits-F';
        return TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: digits.length),
        );
      });

  static bool isCrefito(String value) => _crefitoPattern.hasMatch(value.trim());

  static String buildCrefito(String region, String number) =>
      'CREFITO-${int.tryParse(region) ?? region}/${digitsOnly(number)}-F';

  /// Separa um CREFITO salvo em região e número; null se estiver fora do padrão.
  static ({String region, String number})? parseCrefito(String value) {
    final match = _crefitoPattern.firstMatch(value.trim().toUpperCase());
    if (match == null) return null;
    return (region: match.group(1)!, number: match.group(2)!);
  }

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
