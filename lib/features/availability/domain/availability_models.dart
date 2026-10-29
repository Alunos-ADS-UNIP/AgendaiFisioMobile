/// Modelos de domínio da disponibilidade do fisioterapeuta (B-FE-04).
///
/// IMPORTANTE: o backend ainda NÃO define duração de consulta, intervalo nem
/// regra de sobreposição. Por isso estes modelos guardam apenas horários
/// (hora/minuto) e não assumem nenhuma dessas regras.
library;

/// Horário do dia sem data (ex.: 08:00). Usado para turnos.
class TimeOfDayValue implements Comparable<TimeOfDayValue> {
  const TimeOfDayValue(this.hour, this.minute)
    : assert(hour >= 0 && hour < 24),
      assert(minute >= 0 && minute < 60);

  final int hour;
  final int minute;

  int get totalMinutes => hour * 60 + minute;

  @override
  int compareTo(TimeOfDayValue other) =>
      totalMinutes.compareTo(other.totalMinutes);

  @override
  bool operator ==(Object other) =>
      other is TimeOfDayValue && other.totalMinutes == totalMinutes;

  @override
  int get hashCode => totalMinutes.hashCode;

  /// Texto para a UI, ex.: "08:00".
  String get label =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  String toString() => label;
}

/// Um turno: faixa de início/fim em um dia (ex.: 08:00–12:00).
class TimeRange {
  const TimeRange({required this.start, required this.end});

  final TimeOfDayValue start;
  final TimeOfDayValue end;

  /// Válido apenas se o fim é depois do início.
  bool get isValid => start.compareTo(end) < 0;

  /// Verdadeiro se as faixas se tocam em mais que um ponto.
  bool overlaps(TimeRange other) =>
      start.compareTo(other.end) < 0 && other.start.compareTo(end) < 0;

  String get label => '${start.label} – ${end.label}';

  @override
  bool operator ==(Object other) =>
      other is TimeRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// Dias da semana (segunda a domingo), alinhados a [DateTime.weekday].
enum WeekDay {
  monday(DateTime.monday, 'Segunda-feira'),
  tuesday(DateTime.tuesday, 'Terça-feira'),
  wednesday(DateTime.wednesday, 'Quarta-feira'),
  thursday(DateTime.thursday, 'Quinta-feira'),
  friday(DateTime.friday, 'Sexta-feira'),
  saturday(DateTime.saturday, 'Sábado'),
  sunday(DateTime.sunday, 'Domingo');

  const WeekDay(this.isoNumber, this.label);

  final int isoNumber;
  final String label;

  static WeekDay fromDate(DateTime date) =>
      WeekDay.values.firstWhere((d) => d.isoNumber == date.weekday);
}

/// Motivos de erro de validação de um dia.
enum ShiftValidationError { invalidRange, overlap }

/// Disponibilidade de um dia: ativo/inativo e seus turnos.
class DayAvailability {
  const DayAvailability({
    required this.day,
    this.enabled = false,
    this.shifts = const [],
  });

  final WeekDay day;
  final bool enabled;
  final List<TimeRange> shifts;

  DayAvailability copyWith({bool? enabled, List<TimeRange>? shifts}) =>
      DayAvailability(
        day: day,
        enabled: enabled ?? this.enabled,
        shifts: shifts ?? this.shifts,
      );

  /// Valida turnos. Lista vazia = dia válido.
  /// Um dia ativo sem turnos também é inválido para salvar.
  List<ShiftValidationError> validate() {
    final errors = <ShiftValidationError>[];
    if (!enabled) return errors;
    if (shifts.any((s) => !s.isValid)) {
      errors.add(ShiftValidationError.invalidRange);
    }
    final sorted = [...shifts.where((s) => s.isValid)]
      ..sort((a, b) => a.start.compareTo(b.start));
    for (var i = 1; i < sorted.length; i++) {
      if (sorted[i - 1].overlaps(sorted[i])) {
        errors.add(ShiftValidationError.overlap);
        break;
      }
    }
    return errors;
  }

  bool get isValid => validate().isEmpty;
}

/// Grade semanal completa (sempre 7 dias, segunda a domingo).
class WeeklySchedule {
  WeeklySchedule({required List<DayAvailability> days})
    : days = List.unmodifiable(_normalize(days));

  /// Grade vazia: nenhum dia ativo.
  factory WeeklySchedule.empty() => WeeklySchedule(days: const []);

  final List<DayAvailability> days;

  static List<DayAvailability> _normalize(List<DayAvailability> input) {
    return [
      for (final d in WeekDay.values)
        input.firstWhere(
          (x) => x.day == d,
          orElse: () => DayAvailability(day: d),
        ),
    ];
  }

  DayAvailability dayOf(WeekDay day) => days.firstWhere((d) => d.day == day);

  WeeklySchedule withDay(DayAvailability updated) => WeeklySchedule(
    days: [for (final d in days) d.day == updated.day ? updated : d],
  );

  bool get hasAnyActiveDay => days.any((d) => d.enabled && d.shifts.isNotEmpty);

  bool get isValid => days.every((d) => d.isValid);
}

/// Estado visual de um horário. Nunca depender só de cor: usar texto/ícone.
enum SlotState { free, selected, busy, disabled }

/// Horário calculado para uma data específica.
///
/// [start] é a data/hora local para exibir. A conversão de/para UTC (ISO 8601)
/// fica na camada de dados quando o contrato do backend existir.
class AvailableSlot {
  const AvailableSlot({required this.start, required this.state});

  final DateTime start;
  final SlotState state;

  String get label =>
      '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';

  bool get isSelectable => state == SlotState.free;

  AvailableSlot copyWith({SlotState? state}) =>
      AvailableSlot(start: start, state: state ?? this.state);
}
