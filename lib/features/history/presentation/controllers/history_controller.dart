import 'package:flutter/foundation.dart';

import '../../domain/appointment_history_entry.dart';
import '../../domain/history_failure.dart';

typedef HistoryPageLoader = Future<AppointmentHistoryPage> Function(
  int page,
  int pageSize,
);

/// Paginação incremental do histórico, compartilhada pelas visões do paciente
/// e do profissional. Mantém a ordem da API e descarta itens repetidos.
class HistoryController extends ChangeNotifier {
  HistoryController({required this.loadPage, this.pageSize = 20});

  final HistoryPageLoader loadPage;
  final int pageSize;

  final List<AppointmentHistoryEntry> _items = [];
  final Set<String> _ids = {};
  int _nextPage = 1;
  int _generation = 0;

  bool _isLoadingFirstPage = false;
  bool _isLoadingMore = false;
  bool _hasReachedEnd = false;
  bool _hasLoaded = false;
  HistoryFailure? _failure;
  HistoryFailure? _loadMoreFailure;

  List<AppointmentHistoryEntry> get items => List.unmodifiable(_items);
  bool get isLoadingFirstPage => _isLoadingFirstPage;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasReachedEnd => _hasReachedEnd;

  /// Falha no carregamento inicial; a tela inteira mostra o erro.
  HistoryFailure? get failure => _failure;

  /// Falha ao buscar a próxima página; os itens já carregados continuam.
  HistoryFailure? get loadMoreFailure => _loadMoreFailure;

  bool get isEmpty => _hasLoaded && _failure == null && _items.isEmpty;

  bool get canLoadMore =>
      _hasLoaded &&
      !_hasReachedEnd &&
      !_isLoadingFirstPage &&
      !_isLoadingMore &&
      _failure == null &&
      _loadMoreFailure == null;

  /// Carrega (ou recarrega) a partir da primeira página.
  Future<void> loadFirstPage() async {
    final generation = ++_generation;
    _items.clear();
    _ids.clear();
    _nextPage = 1;
    _hasReachedEnd = false;
    _hasLoaded = false;
    _isLoadingMore = false;
    _failure = null;
    _loadMoreFailure = null;
    _isLoadingFirstPage = true;
    notifyListeners();

    try {
      final page = await loadPage(1, pageSize);
      if (generation != _generation) return;
      _append(page);
    } on HistoryException catch (error) {
      if (generation != _generation) return;
      _failure = error.failure;
    } finally {
      if (generation == _generation) {
        _isLoadingFirstPage = false;
        _hasLoaded = true;
        notifyListeners();
      }
    }
  }

  /// Busca a próxima página. Ignorado durante outra carga ou após o fim.
  Future<void> loadNextPage() async {
    if (!canLoadMore) return;

    final generation = _generation;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final page = await loadPage(_nextPage, pageSize);
      if (generation != _generation) return;
      _append(page);
    } on HistoryException catch (error) {
      if (generation != _generation) return;
      _loadMoreFailure = error.failure;
    } finally {
      if (generation == _generation) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  /// Tenta novamente a página que falhou.
  Future<void> retryLoadMore() {
    _loadMoreFailure = null;
    return loadNextPage();
  }

  void _append(AppointmentHistoryPage page) {
    for (final item in page.items) {
      if (_ids.add(item.appointmentId)) _items.add(item);
    }
    _nextPage = page.currentPage + 1;
    _hasReachedEnd = page.isLastPage;
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }
}
