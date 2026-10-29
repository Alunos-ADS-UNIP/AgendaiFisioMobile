const _weekdays = [
  'segunda-feira',
  'terça-feira',
  'quarta-feira',
  'quinta-feira',
  'sexta-feira',
  'sábado',
  'domingo',
];

const _shortMonths = [
  'jan.',
  'fev.',
  'mar.',
  'abr.',
  'mai.',
  'jun.',
  'jul.',
  'ago.',
  'set.',
  'out.',
  'nov.',
  'dez.',
];

/// Data em português com dia da semana por extenso e mês abreviado, em uma
/// linha só: "quinta-feira, 29 de out. de 2026".
String weekdayShortMonthDate(DateTime date) =>
    '${_weekdays[date.weekday - 1]}, ${date.day} de '
    '${_shortMonths[date.month - 1]} de ${date.year}';
