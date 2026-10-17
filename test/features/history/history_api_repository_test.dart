import 'dart:convert';

import 'package:agendaifisiomobile/core/models/appointment_status.dart';
import 'package:agendaifisiomobile/features/history/data/dtos/history_page_dto.dart';
import 'package:agendaifisiomobile/features/history/data/history_api_repository.dart';
import 'package:agendaifisiomobile/features/history/domain/history_failure.dart';
import 'package:flutter_test/flutter_test.dart';

// Exemplo de docs/historico-consultas.md do backend.
const _apiExample = {
  'itens': [
    {
      'agendamentoId': 'bd66b8c6-a556-4aca-9bd4-15ec94f8a807',
      'dataHora': '2026-10-01T17:00:00Z',
      'profissionalId': '134f9b7a-0e24-42b8-92ef-835d8a58543d',
      'profissionalNome': 'Ana Silva',
      'status': 'Concluido',
    },
  ],
  'totalRegistros': 1,
  'paginaAtual': 1,
  'tamanhoPagina': 10,
  'totalPaginas': 1,
};

void main() {
  group('HistoryPageDto', () {
    test('lê o JSON real da API e converte a data para o fuso local', () {
      final page = HistoryPageDto.fromJson(_apiExample).toPage();

      expect(page.items, hasLength(1));
      final entry = page.items.single;
      expect(entry.appointmentId, 'bd66b8c6-a556-4aca-9bd4-15ec94f8a807');
      expect(entry.professionalName, 'Ana Silva');
      expect(entry.status, AppointmentStatus.completed);
      expect(entry.dateTime.isUtc, isFalse);
      expect(entry.dateTime, DateTime.utc(2026, 10, 1, 17).toLocal());
      expect(page.isLastPage, isTrue);
    });

    test('página além do fim vem vazia e é a última', () {
      final page = HistoryPageDto.fromJson({
        ..._apiExample,
        'itens': <Object>[],
        'paginaAtual': 2,
      }).toPage();

      expect(page.items, isEmpty);
      expect(page.isLastPage, isTrue);
    });

    test('converte todos os status do backend', () {
      expect(parseApiStatus('Agendado'), AppointmentStatus.scheduled);
      expect(parseApiStatus('Confirmado'), AppointmentStatus.confirmed);
      expect(parseApiStatus('Cancelado'), AppointmentStatus.cancelled);
      expect(parseApiStatus('Concluido'), AppointmentStatus.completed);
      expect(() => parseApiStatus('Inventado'), throwsFormatException);
    });
  });

  group('HistoryApiRepository', () {
    late List<(String, Map<String, String>)> calls;
    late HistoryHttpResponse response;

    HistoryApiRepository repository() {
      return HistoryApiRepository((path, query) async {
        calls.add((path, query));
        return response;
      });
    }

    setUp(() {
      calls = [];
      response = HistoryHttpResponse(
        statusCode: 200,
        body: jsonEncode(_apiExample),
      );
    });

    test('paciente usa somente a rota /me, sem ID', () async {
      final page = await repository().fetchMyHistory(page: 2, pageSize: 20);

      expect(calls.single.$1, '/api/paciente/me/historico-consultas');
      expect(calls.single.$2, {'pagina': '2', 'tamanhoPagina': '20'});
      expect(page.items.single.professionalName, 'Ana Silva');
    });

    test('profissional usa a rota com pacienteId', () async {
      await repository().fetchPatientHistory(
        patientId: 'abc-123',
        page: 1,
        pageSize: 10,
      );

      expect(calls.single.$1, '/api/paciente/abc-123/historico-consultas');
    });

    for (final status in [403, 404]) {
      test('$status vira acesso negado, sem diferenciar', () async {
        response = HistoryHttpResponse(statusCode: status, body: '');

        await expectLater(
          repository().fetchPatientHistory(
            patientId: 'x',
            page: 1,
            pageSize: 10,
          ),
          throwsA(
            isA<HistoryException>().having(
              (e) => e.failure,
              'failure',
              HistoryFailure.accessDenied,
            ),
          ),
        );
      });
    }

    test('401 vira sessão expirada', () async {
      response = const HistoryHttpResponse(statusCode: 401, body: '');

      await expectLater(
        repository().fetchMyHistory(page: 1, pageSize: 10),
        throwsA(
          isA<HistoryException>().having(
            (e) => e.failure,
            'failure',
            HistoryFailure.sessionExpired,
          ),
        ),
      );
    });

    test('falha de transporte vira erro de rede', () async {
      final repository = HistoryApiRepository(
        (_, _) => Future.error(Exception('sem conexão')),
      );

      await expectLater(
        repository.fetchMyHistory(page: 1, pageSize: 10),
        throwsA(
          isA<HistoryException>().having(
            (e) => e.failure,
            'failure',
            HistoryFailure.network,
          ),
        ),
      );
    });

    test('JSON inválido vira erro inesperado', () async {
      response = const HistoryHttpResponse(statusCode: 200, body: '{}');

      await expectLater(
        repository().fetchMyHistory(page: 1, pageSize: 10),
        throwsA(
          isA<HistoryException>().having(
            (e) => e.failure,
            'failure',
            HistoryFailure.unexpected,
          ),
        ),
      );
    });
  });
}
