import 'package:flutter/foundation.dart';

import '../../domain/availability_failure.dart';
import '../../domain/availability_models.dart';
import '../../domain/availability_repository.dart';

/// Horários de um dia do profissional, com a seleção feita na tela.
/// Mesmo padrão do AvailabilityController: `_generation` descarta respostas
/// atrasadas quando o usuário troca de dia rapidamente.
class AvailableSlotsController extends ChangeNotifier {
  AvailableSlotsController({
    required this.repository,
    required this.professionalId,
    DateTime? initialDate,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       date = _dateOnly(initialDate ?? (clock ?? DateTime.now)());

  final AvailabilityRepository repository;
  final String professionalId;
  final DateTime Function() _clock;

  DateTime date;
  List<AvailableSlot> _slots = const [];
  AvailabilityFailure? _failure;
  bool _loading = false;
  int _generation = 0;
  DateTime? _selected;

  List<AvailableSlot> get slots => _slots;
  AvailabilityFailure? get failure => _failure;
  bool get isLoading => _loading;
  DateTime? get selected => _selected;

  /// Não deixa voltar para dias que já passaram.
  bool get canGoBack => date.isAfter(_dateOnly(_clock()));

  bool isSelected(AvailableSlot slot) => _selected == slot.start;

  Future<void> load() async {
    final generation = ++_generation;
    _failure = null;
    _loading = true;
    notifyListeners();
    try {
      final data = await repository.fetchSlots(
        professionalId: professionalId,
        date: date,
      );
      if (generation != _generation) return;
      _slots = data;
    } on AvailabilityException catch (error) {
      if (generation != _generation) return;
      _failure = error.failure;
      _slots = const [];
    } catch (_) {
      if (generation != _generation) return;
      _failure = AvailabilityFailure.unknown;
      _slots = const [];
    } finally {
      if (generation == _generation) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  /// Anda [days] dias e recarrega. A seleção some ao trocar de dia.
  Future<void> changeDay(int days) {
    final next = date.add(Duration(days: days));
    if (days < 0 && !canGoBack) return Future.value();
    date = next;
    _selected = null;
    return load();
  }

  /// Só horários livres podem ser escolhidos; tocar de novo desfaz a escolha.
  void select(AvailableSlot slot) {
    if (!slot.isSelectable) return;
    _selected = isSelected(slot) ? null : slot.start;
    notifyListeners();
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }
}
