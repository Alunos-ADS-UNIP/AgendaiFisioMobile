/// Nome curto para saudações: apenas o primeiro e o último nome.
///
/// "Márcio Cardoso Santos" vira "Márcio Santos". Um nome só continua igual.
String shortPersonName(String? fullName) {
  final parts = (fullName ?? '').trim().split(RegExp(r'\s+'))
    ..removeWhere((part) => part.isEmpty);
  if (parts.isEmpty) return '';
  if (parts.length == 1) return parts.first;
  return '${parts.first} ${parts.last}';
}
