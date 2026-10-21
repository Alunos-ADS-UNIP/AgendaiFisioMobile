import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:agendaifisiomobile/core/models/appointment_status.dart';
import 'package:agendaifisiomobile/features/appointments/data/appointment_api_repository.dart';
import 'package:agendaifisiomobile/features/appointments/domain/appointment_failure.dart';

void main() {
  const token = 'test-token';

  test('POST usa bearer, data UTC e nunca envia pacienteId', () async {
    late http.Request captured;
    final repository = AppointmentApiRepository(
      baseUri: Uri.parse('http://localhost:5048'),
      tokenProvider: () async => token,
      client: MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode(_appointmentJson), 201);
      }),
    );

    final created = await repository.createAppointment(
      professionalId: 'professional-1',
      dateTime: DateTime.utc(2026, 11, 12, 15, 30),
      observations: '  Dor no ombro  ',
    );

    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(captured.method, 'POST');
    expect(captured.url.path, '/api/agendamento');
    expect(captured.headers['authorization'], 'Bearer $token');
    expect(body, containsPair('profissionalId', 'professional-1'));
    expect(body['dataHora'], '2026-11-12T15:30:00.000Z');
    expect(body['observacoes'], 'Dor no ombro');
    expect(body, isNot(contains('pacienteId')));
    expect(created.id, 'appointment-1');
  });

  test('catálogo público não recebe token e aceita envelope da API', () async {
    late http.Request captured;
    final repository = AppointmentApiRepository(
      baseUri: Uri.parse('http://localhost:5048'),
      tokenProvider: () async => token,
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'dados': [
              {'id': 'specialty-1', 'nome': 'Fisioterapia'},
            ],
          }),
          200,
        );
      }),
    );

    final specialties = await repository.fetchSpecialties();

    expect(captured.url.path, '/api/especialidade');
    expect(captured.headers, isNot(contains('authorization')));
    expect(specialties.single.name, 'Fisioterapia');
  });

  test(
    'lista e detalhe dos profissionais exigem bearer e tratam 401',
    () async {
      final captured = <http.Request>[];
      var expired = false;
      final repository = AppointmentApiRepository(
        baseUri: Uri.parse('http://localhost:5048'),
        tokenProvider: () async => token,
        onUnauthorized: () async {
          expired = true;
        },
        client: MockClient((request) async {
          captured.add(request);
          return http.Response('', 401);
        }),
      );
      await expectLater(
        repository.fetchProfessionals(),
        throwsA(isA<AppointmentException>()),
      );
      await expectLater(
        repository.fetchProfessional('professional-1'),
        throwsA(isA<AppointmentException>()),
      );
      expect(captured, hasLength(2));
      for (final request in captured) {
        expect(request.headers['authorization'], 'Bearer $token');
        expect(request.followRedirects, isFalse);
      }
      expect(expired, isTrue);
    },
  );

  test('GET de agenda envia token e converte data/status', () async {
    late http.Request captured;
    final repository = AppointmentApiRepository(
      baseUri: Uri.parse('http://localhost:5048'),
      tokenProvider: () async => token,
      client: MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode([_appointmentJson]), 200);
      }),
    );

    final items = await repository.fetchAppointments();

    expect(captured.headers['authorization'], 'Bearer $token');
    expect(items.single.status, AppointmentStatus.confirmed);
    expect(items.single.dateTime.isUtc, isFalse);
  });

  test('conflito 409 fica tipado para a tela preservar a seleção', () async {
    final repository = AppointmentApiRepository(
      baseUri: Uri.parse('http://localhost:5048'),
      tokenProvider: () async => token,
      client: MockClient((_) async => http.Response('', 409)),
    );

    await expectLater(
      repository.createAppointment(
        professionalId: 'professional-1',
        dateTime: DateTime.utc(2026, 11, 12, 15),
      ),
      throwsA(
        isA<AppointmentException>().having(
          (error) => error.failure,
          'failure',
          AppointmentFailure.conflict,
        ),
      ),
    );
  });

  test('401 chama o encerramento global da sessão', () async {
    var expired = false;
    final repository = AppointmentApiRepository(
      baseUri: Uri.parse('http://localhost:5048'),
      tokenProvider: () async => token,
      onUnauthorized: () async => expired = true,
      client: MockClient((_) async => http.Response('', 401)),
    );

    await expectLater(
      repository.fetchAppointments(),
      throwsA(isA<AppointmentException>()),
    );
    expect(expired, isTrue);
  });
}

const _appointmentJson = {
  'id': 'appointment-1',
  'pacienteId': 'patient-1',
  'profissionalId': 'professional-1',
  'profissionalNome': 'Dra. Marina',
  'dataHora': '2026-11-12T15:30:00Z',
  'status': 'Confirmado',
  'observacoes': 'Consulta de retorno',
};
