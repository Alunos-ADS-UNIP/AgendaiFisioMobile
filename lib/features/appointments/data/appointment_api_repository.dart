import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/models/appointment_status.dart';
import '../domain/appointment.dart';
import '../domain/appointment_failure.dart';
import '../domain/appointment_filters.dart';
import '../domain/appointment_repository.dart';
import '../domain/professional.dart';
import '../domain/specialty.dart';

typedef AppointmentTokenProvider = Future<String?> Function();
typedef SessionExpiredCallback = Future<void> Function();

/// Repositório HTTP da agenda. O token só é anexado a chamadas da mesma origem
/// configurada e nunca é enviado ao catálogo público nem a redirecionamentos.
class AppointmentApiRepository implements AppointmentRepository {
  AppointmentApiRepository({
    required Uri baseUri,
    required this._tokenProvider,
    this._onUnauthorized,
    http.Client? client,
  }) : _baseUri = _normalizeBaseUri(baseUri),
       _client = client ?? http.Client(),
       _ownsClient = client == null;

  final Uri _baseUri;
  final AppointmentTokenProvider _tokenProvider;
  final SessionExpiredCallback? _onUnauthorized;
  final http.Client _client;
  final bool _ownsClient;
  final Map<String, Professional> _professionals = {};

  static Uri _normalizeBaseUri(Uri uri) {
    if (!uri.hasAuthority || (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw ArgumentError.value(
        uri,
        'baseUri',
        'Use uma origem HTTP ou HTTPS.',
      );
    }
    return uri.replace(path: '', query: null, fragment: null);
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = _baseUri.resolve(path);
    if (uri.origin != _baseUri.origin) {
      throw StateError('A solicitação saiu da origem configurada.');
    }
    return query == null ? uri : uri.replace(queryParameters: query);
  }

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    bool authenticated = false,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json';
    if (authenticated) {
      final token = await _tokenProvider();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    try {
      final request = http.Request(method, _uri(path, query))
        ..followRedirects = false
        ..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 401 && authenticated) {
        await _onUnauthorized?.call();
      }
      return response;
    } on AppointmentException {
      rethrow;
    } on TimeoutException {
      throw const AppointmentException(AppointmentFailure.network);
    } on http.ClientException {
      throw const AppointmentException(AppointmentFailure.network);
    } catch (error) {
      if (error is AppointmentException) rethrow;
      throw const AppointmentException(AppointmentFailure.network);
    }
  }

  @override
  Future<List<Appointment>> fetchAppointments({
    AppointmentFilters filters = const AppointmentFilters(),
  }) async {
    final query = <String, String>{};
    if (filters.day case final day?) {
      query['data'] = DateTime(
        day.year,
        day.month,
        day.day,
      ).toUtc().toIso8601String();
    }
    if (filters.professionalId case final id?) query['profissionalId'] = id;
    if (filters.status case final status?) {
      query['status'] = _statusToApi(status);
    }

    final response = await _send(
      'GET',
      '/api/agendamento',
      query: query.isEmpty ? null : query,
      authenticated: true,
    );
    if (response.statusCode != 200) _throwForStatus(response.statusCode);
    try {
      final rows = _readList(jsonDecode(response.body));
      final appointments = rows.map(_appointmentFromJson).toList();
      return appointments..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    } catch (_) {
      throw const AppointmentException(AppointmentFailure.unexpected);
    }
  }

  @override
  Future<Appointment> fetchAppointment(String id) async {
    final response = await _send(
      'GET',
      '/api/agendamento/${Uri.encodeComponent(id)}',
      authenticated: true,
    );
    if (response.statusCode != 200) _throwForStatus(response.statusCode);
    try {
      final json = _readMap(jsonDecode(response.body));
      var appointment = _appointmentFromJson(json);
      try {
        final professional = await fetchProfessional(
          appointment.professionalId,
        );
        appointment = Appointment(
          id: appointment.id,
          professionalId: appointment.professionalId,
          professionalName: appointment.professionalName.isEmpty
              ? professional.name
              : appointment.professionalName,
          dateTime: appointment.dateTime,
          status: appointment.status,
          specialtyName: professional.specialtyName,
          observations: appointment.observations,
        );
      } on AppointmentException catch (error) {
        if (error.failure == AppointmentFailure.unauthorized) rethrow;
      }
      return appointment;
    } on AppointmentException {
      rethrow;
    } catch (_) {
      throw const AppointmentException(AppointmentFailure.unexpected);
    }
  }

  @override
  Future<Appointment> createAppointment({
    required String professionalId,
    required DateTime dateTime,
    String? observations,
  }) async {
    final normalizedNotes = observations?.trim();
    final body = <String, Object?>{
      'profissionalId': professionalId,
      // UTC Z avoids ambiguous local timestamps and matches the API contract.
      'dataHora': dateTime.toUtc().toIso8601String(),
      if (normalizedNotes != null && normalizedNotes.isNotEmpty)
        'observacoes': normalizedNotes,
    };
    final response = await _send(
      'POST',
      '/api/agendamento',
      body: body,
      authenticated: true,
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      _throwForStatus(response.statusCode);
    }
    try {
      final appointment = _appointmentFromJson(
        _readMap(jsonDecode(response.body)),
      );
      _professionals.remove(professionalId);
      return appointment;
    } catch (_) {
      throw const AppointmentException(AppointmentFailure.unexpected);
    }
  }

  @override
  Future<List<Professional>> fetchProfessionals({
    String? specialtyId,
    bool? active,
    int page = 1,
    int pageSize = 20,
  }) async {
    final query = <String, String>{
      'pagina': '$page',
      'tamanhoPagina': '$pageSize',
      'especialidadeId': ?specialtyId,
      if (active != null) 'ativo': '$active',
    };
    final response = await _send('GET', '/api/profissional', query: query);
    if (response.statusCode != 200) _throwForStatus(response.statusCode);
    try {
      return _readList(jsonDecode(response.body))
          .map((row) {
            final professional = _professionalFromJson(row);
            _professionals[professional.id] = professional;
            return professional;
          })
          .toList(growable: false);
    } on AppointmentException {
      rethrow;
    } catch (_) {
      throw const AppointmentException(AppointmentFailure.unexpected);
    }
  }

  @override
  Future<Professional> fetchProfessional(String id) async {
    final cached = _professionals[id];
    if (cached != null) return cached;
    final response = await _send(
      'GET',
      '/api/profissional/${Uri.encodeComponent(id)}',
    );
    if (response.statusCode != 200) _throwForStatus(response.statusCode);
    try {
      final professional = _professionalFromJson(
        _readMap(jsonDecode(response.body)),
      );
      _professionals[id] = professional;
      return professional;
    } on AppointmentException {
      rethrow;
    } catch (_) {
      throw const AppointmentException(AppointmentFailure.unexpected);
    }
  }

  @override
  Future<List<Specialty>> fetchSpecialties() async {
    final response = await _send('GET', '/api/especialidade');
    if (response.statusCode != 200) _throwForStatus(response.statusCode);
    try {
      return _readList(jsonDecode(response.body))
          .map((row) {
            final json = _readMap(row);
            return Specialty(
              id: _string(json, const ['id', 'especialidadeId']),
              name: _string(json, const ['nome', 'name']),
            );
          })
          .where((item) => item.id.isNotEmpty && item.name.isNotEmpty)
          .toList(growable: false);
    } on AppointmentException {
      rethrow;
    } catch (_) {
      throw const AppointmentException(AppointmentFailure.unexpected);
    }
  }

  Appointment _appointmentFromJson(Map<String, dynamic> json) {
    final id = _string(json, const ['id', 'agendamentoId']);
    final professionalId = _string(json, const ['profissionalId']);
    final rawDate = _string(json, const ['dataHora', 'dateTime']);
    final parsedDate = DateTime.tryParse(rawDate);
    if (id.isEmpty || professionalId.isEmpty || parsedDate == null) {
      throw const FormatException('Resposta de agendamento inválida.');
    }
    return Appointment(
      id: id,
      professionalId: professionalId,
      professionalName: _string(json, const [
        'profissionalNome',
        'nomeProfissional',
      ]),
      dateTime: parsedDate.toLocal(),
      status: _statusFromApi(_string(json, const ['status'])),
      specialtyName: _string(json, const ['especialidadeNome']),
      observations: _nullableString(json, const ['observacoes']),
    );
  }

  Professional _professionalFromJson(Map<String, dynamic> json) {
    final specialty = _value(json, const ['especialidade']);
    final specialtyMap = specialty is Map
        ? Map<String, dynamic>.from(specialty)
        : null;
    final id = _string(json, const ['id', 'profissionalId']);
    final name = _string(json, const [
      'nomeCompleto',
      'nome',
      'profissionalNome',
    ]);
    if (id.isEmpty || name.isEmpty) {
      throw const FormatException('Profissional inválido.');
    }
    return Professional(
      id: id,
      name: name,
      specialtyId:
          _nullableString(json, const ['especialidadeId']) ??
          (specialtyMap == null
              ? null
              : _string(specialtyMap, const ['id', 'especialidadeId'])),
      specialtyName:
          _string(json, const [
            'especialidadeNome',
            'nomeEspecialidade',
          ]).isNotEmpty
          ? _string(json, const ['especialidadeNome', 'nomeEspecialidade'])
          : (specialtyMap == null
                ? ''
                : _string(specialtyMap, const ['nome', 'name'])),
      crefito: _string(json, const ['crefito']),
      bio: _string(json, const ['bio', 'biografia']),
      isActive: _bool(json, const ['ativo', 'isActive'], fallback: true),
    );
  }

  static dynamic _value(Map<String, dynamic> map, List<String> keys) {
    for (final entry in map.entries) {
      if (keys.any((key) => key.toLowerCase() == entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return null;
  }

  static String _string(Map<String, dynamic> map, List<String> keys) =>
      _value(map, keys)?.toString() ?? '';

  static String? _nullableString(Map<String, dynamic> map, List<String> keys) {
    final value = _value(map, keys);
    return value?.toString();
  }

  static bool _bool(
    Map<String, dynamic> map,
    List<String> keys, {
    required bool fallback,
  }) {
    final value = _value(map, keys);
    if (value is bool) return value;
    return fallback;
  }

  static Map<String, dynamic> _readMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException('Objeto JSON esperado.');
  }

  static List<Map<String, dynamic>> _readList(dynamic value) {
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      final wrapped = _value(map, const [
        'itens',
        'items',
        'dados',
        'data',
        'resultados',
      ]);
      if (wrapped != null) return _readList(wrapped);
    }
    if (value is! List) throw const FormatException('Lista JSON esperada.');
    return value.map(_readMap).toList(growable: false);
  }

  static AppointmentStatus _statusFromApi(String raw) {
    final value = raw
        .toLowerCase()
        .replaceAll('í', 'i')
        .replaceAll('ã', 'a')
        .replaceAll('á', 'a')
        .replaceAll('ó', 'o')
        .replaceAll(RegExp('[^a-z]'), '');
    return switch (value) {
      'confirmado' || 'confirmed' => AppointmentStatus.confirmed,
      'emandamento' || 'inprogress' => AppointmentStatus.inProgress,
      'concluido' || 'finalizado' || 'completed' => AppointmentStatus.completed,
      'cancelado' || 'cancelled' || 'canceled' => AppointmentStatus.cancelled,
      'falta' || 'naocompareceu' || 'missed' => AppointmentStatus.missed,
      _ => AppointmentStatus.scheduled,
    };
  }

  static String _statusToApi(AppointmentStatus status) => switch (status) {
    AppointmentStatus.scheduled => 'Agendado',
    AppointmentStatus.confirmed => 'Confirmado',
    AppointmentStatus.inProgress => 'EmAndamento',
    AppointmentStatus.completed => 'Concluido',
    AppointmentStatus.cancelled => 'Cancelado',
    AppointmentStatus.missed => 'Falta',
  };

  Never _throwForStatus(int status) {
    throw AppointmentException(switch (status) {
      401 => AppointmentFailure.unauthorized,
      404 => AppointmentFailure.notFound,
      409 => AppointmentFailure.conflict,
      400 || 422 => AppointmentFailure.invalid,
      _ => AppointmentFailure.unexpected,
    });
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}
