import 'package:flutter/foundation.dart';

import '../../domain/availability_failure.dart';
import '../../domain/availability_models.dart';
import '../../domain/availability_repository.dart';

/// Carrega a grade semanal. Mesmo padrão do AppointmentsController:
/// `_generation` descarta respostas atrasadas.
class AvailabilityController extends ChangeNotifier {
  AvailabilityController({required this.repository});

  final AvailabilityRepository repository;

  WeeklySchedule? _schedule;
  AvailabilityFailure? _failure;
  bool _loading = false;
  int _generation = 0;

  WeeklySchedule? get schedule => _schedule;
  AvailabilityFailure? get failure => _failure;
  bool get isLoading => _loading;

  /// Grade carregada, mas sem nenhum dia ativo com turno.
  bool get isEmpty =>
      !_loading &&
      _failure == null &&
      _schedule != null &&
      !_schedule!.hasAnyActiveDay;

  /// O backend ainda não oferece esta funcionalidade.
  bool get isUnavailable => _failure == AvailabilityFailure.unavailable;

  Future<void> load() async {
    final generation = ++_generation;
    _failure = null;
    _loading = true;
    notifyListeners();
    try {
      final data = await repository.fetchWeeklySchedule();
      if (generation != _generation) return;
      _schedule = data;
    } on AvailabilityException catch (error) {
      if (generation != _generation) return;
      _failure = error.failure;
      _schedule = null;
    } catch (_) {
      if (generation != _generation) return;
      _failure = AvailabilityFailure.unknown;
      _schedule = null;
    } finally {
      if (generation == _generation) {
        _loading = false;
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
