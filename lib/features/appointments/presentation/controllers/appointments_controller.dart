import 'package:flutter/foundation.dart';

import '../../domain/appointment.dart';
import '../../domain/appointment_failure.dart';
import '../../domain/appointment_filters.dart';
import '../../domain/appointment_repository.dart';

class AppointmentsController extends ChangeNotifier {
  AppointmentsController({required this.repository, this.pageSize = 20});

  final AppointmentRepository repository;
  final int pageSize;
  List<Appointment> _allItems = const [];
  List<Appointment> _visibleItems = const [];
  AppointmentFilters _filters = const AppointmentFilters();
  AppointmentFailure? _failure;
  bool _loading = false;
  int _page = 1;
  int _generation = 0;

  List<Appointment> get items => List.unmodifiable(_visibleItems);
  AppointmentFilters get filters => _filters;
  AppointmentFailure? get failure => _failure;
  bool get isLoading => _loading;
  int get page => _page;
  int get totalPages => (_allItems.length / pageSize).ceil().clamp(1, 1 << 30);
  bool get isEmpty => !_loading && _failure == null && _visibleItems.isEmpty;
  bool get canGoBack => _page > 1;
  bool get canGoForward => _page < totalPages;

  Future<void> load({AppointmentFilters? filters}) async {
    final generation = ++_generation;
    if (filters != null) _filters = filters;
    _page = 1;
    _failure = null;
    _loading = true;
    notifyListeners();
    try {
      final data = await repository.fetchAppointments(filters: _filters);
      if (generation != _generation) return;
      // Ordem cronológica (data e horário), independente da ordem que a API devolve.
      _allItems = _filters.apply(data)
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      _updatePageItems();
    } on AppointmentException catch (error) {
      if (generation != _generation) return;
      _failure = error.failure;
      _allItems = const [];
      _visibleItems = const [];
    } catch (_) {
      if (generation != _generation) return;
      _failure = AppointmentFailure.unexpected;
      _allItems = const [];
      _visibleItems = const [];
    } finally {
      if (generation == _generation) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  void goToPage(int page) {
    if (_loading || page < 1 || page > totalPages || page == _page) return;
    _page = page;
    _updatePageItems();
    notifyListeners();
  }

  void _updatePageItems() {
    final start = (_page - 1) * pageSize;
    if (start >= _allItems.length) {
      _page = totalPages;
    }
    final safeStart = (_page - 1) * pageSize;
    final end = (safeStart + pageSize).clamp(0, _allItems.length);
    _visibleItems = _allItems.sublist(safeStart.clamp(0, end), end);
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }
}
