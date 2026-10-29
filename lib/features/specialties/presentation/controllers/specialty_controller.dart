import 'package:flutter/foundation.dart';

import '../../domain/entities/specialty.dart';
import '../../domain/repositories/specialty_repository.dart';
import '../../domain/specialty_failure.dart';
import '../../domain/specialty_name_normalizer.dart';

enum SpecialtyCatalogStatus { initial, loading, loaded, empty, error, offline }

class SpecialtyCatalogState {
  const SpecialtyCatalogState({
    this.status = SpecialtyCatalogStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  final SpecialtyCatalogStatus status;
  final List<Specialty> items;
  final String? errorMessage;

  SpecialtyCatalogState copyWith({
    SpecialtyCatalogStatus? status,
    List<Specialty>? items,
    String? errorMessage,
    bool clearError = false,
  }) => SpecialtyCatalogState(
    status: status ?? this.status,
    items: items ?? this.items,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}

class SpecialtyCatalogController extends ChangeNotifier {
  SpecialtyCatalogController({required this.repository});

  final SpecialtyRepository repository;
  SpecialtyCatalogState _state = const SpecialtyCatalogState();

  SpecialtyCatalogState get state => _state;

  Future<void> load({bool refresh = false}) async {
    _state = _state.copyWith(
      status: SpecialtyCatalogStatus.loading,
      clearError: true,
    );
    notifyListeners();
    try {
      final items = _deduplicate(await repository.list());
      _state = _state.copyWith(
        status: items.isEmpty
            ? SpecialtyCatalogStatus.empty
            : SpecialtyCatalogStatus.loaded,
        items: items,
        clearError: true,
      );
    } on SpecialtyException catch (error) {
      _state = _state.copyWith(
        status: error.failure == SpecialtyFailure.network
            ? SpecialtyCatalogStatus.offline
            : SpecialtyCatalogStatus.error,
        errorMessage: error.message,
      );
    } catch (_) {
      _state = _state.copyWith(
        status: SpecialtyCatalogStatus.error,
        errorMessage: 'Não foi possível carregar as especialidades.',
      );
    }
    notifyListeners();
  }

  void addCreated(Specialty item) {
    final items = _deduplicate([..._state.items, item]);
    if (items.length == _state.items.length) return;
    _state = _state.copyWith(
      status: SpecialtyCatalogStatus.loaded,
      items: items,
      clearError: true,
    );
    notifyListeners();
  }

  List<Specialty> _deduplicate(List<Specialty> source) {
    final unique = <String, Specialty>{};
    final seenIds = <String>{};
    final seenNames = <String>{};
    for (final item in source) {
      final normalizedName = normalizeSpecialtyName(item.name);
      if (seenIds.add(item.id) && seenNames.add(normalizedName)) {
        unique[item.id] = item;
      }
    }
    final result = unique.values.toList(growable: false);
    return result..sort(
      (a, b) =>
          normalizeSpecialtyName(a.name)
              .compareTo(normalizeSpecialtyName(b.name)),
    );
  }
}

class ProfessionalSpecialtyController extends ChangeNotifier {
  ProfessionalSpecialtyController({required this.repository, this.initialId})
    : selectedId = initialId;

  final SpecialtyRepository repository;
  final String? initialId;
  String? selectedId;
  bool isSaving = false;
  String? errorMessage;

  Future<bool> save(String specialtyId) async {
    if (isSaving) return false;
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      await repository.updateProfessionalSpecialty(specialtyId);
      selectedId = specialtyId;
      return true;
    } on SpecialtyException catch (error) {
      errorMessage = error.message;
      return false;
    } catch (_) {
      errorMessage = 'Não foi possível atualizar a especialidade.';
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}

class ClinicSpecialtyController extends ChangeNotifier {
  ClinicSpecialtyController({required this.repository});

  final SpecialtyRepository repository;
  bool isSaving = false;
  String? errorMessage;

  Future<Specialty?> create(String name) async {
    if (isSaving) return null;
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      return await repository.create(name);
    } on SpecialtyException catch (error) {
      errorMessage = error.message;
      return null;
    } catch (_) {
      errorMessage = 'Não foi possível criar a especialidade.';
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
