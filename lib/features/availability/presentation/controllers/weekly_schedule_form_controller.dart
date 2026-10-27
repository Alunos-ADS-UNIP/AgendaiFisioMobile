import 'package:flutter/foundation.dart';

import '../../domain/availability_failure.dart';
import '../../domain/availability_models.dart';
import '../../domain/availability_repository.dart';

/// Problemas de um dia na edição da grade.
enum DayProblem { noShifts, invalidRange, overlap }

/// Edita a grade semanal em memória e só a envia depois de validada.
/// Salvar passa SEMPRE pelo [AvailabilityRepository]: nada é "gravado" aqui.
class WeeklyScheduleFormController extends ChangeNotifier {
  WeeklyScheduleFormController({
    required this.repository,
    required WeeklySchedule initial,
  }) : _schedule = initial;

  static const defaultShift = TimeRange(
    start: TimeOfDayValue(8, 0),
    end: TimeOfDayValue(12, 0),
  );

  final AvailabilityRepository repository;
  WeeklySchedule _schedule;
  bool _saving = false;
  bool _attemptedSave = false;
  AvailabilityFailure? _failure;
  int _generation = 0;

  WeeklySchedule get schedule => _schedule;
  bool get isSaving => _saving;
  AvailabilityFailure? get failure => _failure;

  /// Depois da primeira tentativa de salvar com erro, a tela mostra o resumo.
  bool get attemptedSave => _attemptedSave;

  /// Problemas do dia, calculados na hora (validação ao vivo).
  List<DayProblem> problemsOf(WeekDay day) {
    final d = _schedule.dayOf(day);
    if (!d.enabled) return const [];
    final problems = <DayProblem>[];
    if (d.shifts.isEmpty) problems.add(DayProblem.noShifts);
    for (final e in d.validate()) {
      problems.add(
        e == ShiftValidationError.invalidRange
            ? DayProblem.invalidRange
            : DayProblem.overlap,
      );
    }
    return problems;
  }

  bool get isValid => WeekDay.values.every((d) => problemsOf(d).isEmpty);

  void _update(DayAvailability day) {
    _schedule = _schedule.withDay(day);
    _failure = null;
    notifyListeners();
  }

  /// Ativa o dia (com um turno padrão se não houver nenhum) ou o desativa,
  /// mantendo os turnos para o caso de reativar.
  void setDayEnabled(WeekDay day, bool enabled) {
    final current = _schedule.dayOf(day);
    if (enabled && current.shifts.isEmpty) {
      _update(current.copyWith(enabled: true, shifts: const [defaultShift]));
    } else {
      _update(current.copyWith(enabled: enabled));
    }
  }

  /// Novo turno logo depois do último (ou o padrão, se não houver turnos).
  void addShift(WeekDay day) {
    final current = _schedule.dayOf(day);
    if (current.shifts.isEmpty) {
      _update(current.copyWith(shifts: const [defaultShift]));
      return;
    }
    final last = current.shifts.last;
    final startMinutes = last.end.totalMinutes;
    final endMinutes = (startMinutes + 60).clamp(0, 23 * 60 + 59);
    final next = TimeRange(
      start: TimeOfDayValue(startMinutes ~/ 60, startMinutes % 60),
      end: TimeOfDayValue(endMinutes ~/ 60, endMinutes % 60),
    );
    _update(current.copyWith(shifts: [...current.shifts, next]));
  }

  void updateShift(WeekDay day, int index, TimeRange shift) {
    final current = _schedule.dayOf(day);
    if (index < 0 || index >= current.shifts.length) return;
    final shifts = [...current.shifts]..[index] = shift;
    _update(current.copyWith(shifts: shifts));
  }

  void removeShift(WeekDay day, int index) {
    final current = _schedule.dayOf(day);
    if (index < 0 || index >= current.shifts.length) return;
    final shifts = [...current.shifts]..removeAt(index);
    _update(current.copyWith(shifts: shifts));
  }

  /// Valida e envia. Devolve true só se o repositório confirmou o salvamento.
  Future<bool> save() async {
    if (_saving) return false;
    if (!isValid) {
      _attemptedSave = true;
      notifyListeners();
      return false;
    }
    final generation = ++_generation;
    _saving = true;
    _failure = null;
    notifyListeners();
    try {
      await repository.saveWeeklySchedule(_schedule);
      return generation == _generation;
    } on AvailabilityException catch (error) {
      if (generation == _generation) _failure = error.failure;
      return false;
    } catch (_) {
      if (generation == _generation) _failure = AvailabilityFailure.unknown;
      return false;
    } finally {
      if (generation == _generation) {
        _saving = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }
}
