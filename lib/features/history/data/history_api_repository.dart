import 'dart:convert';

import '../domain/appointment_history_entry.dart';
import '../domain/history_failure.dart';
import '../domain/history_repository.dart';
import 'dtos/history_page_dto.dart';

/// Resposta HTTP mínima de que o repositório precisa.
class HistoryHttpResponse {
  const HistoryHttpResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}

/// GET autenticado. Deve ser ligado ao cliente HTTP compartilhado
/// (FE-COMUM-01), que injeta o Bearer e trata o 401 globalmente.
typedef HistoryHttpGet = Future<HistoryHttpResponse> Function(
  String path,
  Map<String, String> queryParameters,
);

class HistoryApiRepository implements HistoryRepository {
  const HistoryApiRepository(this._get);

  static const myHistoryPath = '/api/paciente/me/historico-consultas';

  final HistoryHttpGet _get;

  static String patientHistoryPath(String patientId) =>
      '/api/paciente/${Uri.encodeComponent(patientId)}/historico-consultas';

  @override
  Future<AppointmentHistoryPage> fetchMyHistory({
    required int page,
    required int pageSize,
  }) {
    return _fetch(myHistoryPath, page, pageSize);
  }

  @override
  Future<AppointmentHistoryPage> fetchPatientHistory({
    required String patientId,
    required int page,
    required int pageSize,
  }) {
    return _fetch(patientHistoryPath(patientId), page, pageSize);
  }

  Future<AppointmentHistoryPage> _fetch(
    String path,
    int page,
    int pageSize,
  ) async {
    final HistoryHttpResponse response;
    try {
      response = await _get(path, {
        'pagina': '$page',
        'tamanhoPagina': '$pageSize',
      });
    } on HistoryException {
      rethrow;
    } catch (_) {
      throw const HistoryException(HistoryFailure.network);
    }

    switch (response.statusCode) {
      case 200:
        try {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          return HistoryPageDto.fromJson(json).toPage();
        } catch (_) {
          throw const HistoryException(HistoryFailure.unexpected);
        }
      case 401:
        throw const HistoryException(HistoryFailure.sessionExpired);
      case 403:
      case 404:
        throw const HistoryException(HistoryFailure.accessDenied);
      default:
        throw const HistoryException(HistoryFailure.unexpected);
    }
  }
}
