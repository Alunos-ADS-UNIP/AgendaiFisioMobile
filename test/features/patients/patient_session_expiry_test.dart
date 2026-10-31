import 'dart:async';

import 'package:agendaifisiomobile/core/network/api_client.dart';
import 'package:agendaifisiomobile/core/theme/app_theme.dart';
import 'package:agendaifisiomobile/core/widgets/app_loading_skeleton.dart';
import 'package:agendaifisiomobile/core/widgets/error_state.dart';
import 'package:agendaifisiomobile/features/patients/data/dtos/patient_dtos.dart';
import 'package:agendaifisiomobile/features/patients/data/patient_api.dart';
import 'package:agendaifisiomobile/features/patients/domain/patient.dart';
import 'package:agendaifisiomobile/features/patients/presentation/controllers/patient_profile_controller.dart';
import 'package:agendaifisiomobile/features/patients/presentation/controllers/patient_profile_form_controller.dart';
import 'package:agendaifisiomobile/features/patients/presentation/pages/patient_profile_form_page.dart';
import 'package:agendaifisiomobile/features/patients/presentation/pages/patient_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _profileJson =
    '{"nomeCompleto":"Ana Souza","cpf":"","telefone":"",'
    '"dataNascimento":"0001-01-01T00:00:00","sexo":"","estadoCivil":"",'
    '"email":"ana@example.com","endereco":{}}';

PatientApi _api(Future<http.Response> Function(http.Request) handler) =>
    PatientApi(
      ApiClient(
        baseUrl: 'http://backend.test',
        httpClient: MockClient(handler),
      ),
    );

Widget _profilePage(
  PatientProfileController controller, {
  required VoidCallback onLogout,
  required VoidCallback onSessionExpired,
}) => MaterialApp(
  theme: AppTheme.light,
  home: PatientProfilePage(
    controller: controller,
    onEdit: (_) {},
    onLogout: onLogout,
    onSessionExpired: onSessionExpired,
  ),
);

final _request = PatientUpdateRequest(
  nomeCompleto: 'Ana Souza',
  cpf: '12345678901',
  telefone: '11987654321',
  dataNascimento: DateTime(1990, 5, 20),
  sexo: 'Feminino',
  estadoCivil: 'Solteiro(a)',
  endereco: const PatientAddress(),
);

void main() {
  group('skeleton do perfil', () {
    testWidgets('aparece no carregamento e some quando o perfil chega', (
      tester,
    ) async {
      final gate = Completer<http.Response>();
      final controller = PatientProfileController(
        _api((_) => gate.future),
      );

      await tester.pumpWidget(
        _profilePage(controller, onLogout: () {}, onSessionExpired: () {}),
      );
      expect(find.byType(AppLoadingSkeleton), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      gate.complete(http.Response(_profileJson, 200));
      await tester.pumpAndSettle();

      expect(find.byType(AppLoadingSkeleton), findsNothing);
      expect(find.text('Ana Souza'), findsOneWidget);
    });

    testWidgets('some quando o carregamento falha (erro de servidor)', (
      tester,
    ) async {
      var expired = 0;
      final controller = PatientProfileController(
        _api((_) async => http.Response('{}', 500)),
      );

      await tester.pumpWidget(
        _profilePage(
          controller,
          onLogout: () {},
          onSessionExpired: () => expired++,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppLoadingSkeleton), findsNothing);
      expect(find.byType(ErrorState), findsOneWidget);
      expect(expired, 0, reason: '500 não é sessão expirada');
    });
  });

  group('401 no perfil do paciente', () {
    testWidgets('chama onSessionExpired uma vez e não o logout voluntário', (
      tester,
    ) async {
      var logouts = 0;
      var expired = 0;
      final controller = PatientProfileController(
        _api((_) async => http.Response('', 401)),
      );

      await tester.pumpWidget(
        _profilePage(
          controller,
          onLogout: () => logouts++,
          onSessionExpired: () => expired++,
        ),
      );
      await tester.pumpAndSettle();

      expect(expired, 1);
      expect(logouts, 0);
      expect(find.byType(AppLoadingSkeleton), findsNothing);
    });

    testWidgets('sem onSessionExpired, cai no onLogout', (tester) async {
      var logouts = 0;
      final controller = PatientProfileController(
        _api((_) async => http.Response('', 401)),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: PatientProfilePage(
            controller: controller,
            onEdit: (_) {},
            onLogout: () => logouts++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(logouts, 1);
    });
  });

  group('401 ao salvar o formulário', () {
    test('controller marca sessão expirada só em 401', () async {
      final unauthorized = PatientProfileFormController(
        _api((_) async => http.Response('', 401)),
      );
      expect(await unauthorized.submit(_request), isFalse);
      expect(unauthorized.isSessionExpired, isTrue);

      final serverError = PatientProfileFormController(
        _api((_) async => http.Response('{}', 500)),
      );
      expect(await serverError.submit(_request), isFalse);
      expect(serverError.isSessionExpired, isFalse);

      final ok = PatientProfileFormController(
        _api((_) async => http.Response('{}', 200)),
      );
      expect(await ok.submit(_request), isTrue);
      expect(ok.isSessionExpired, isFalse);
    });

    testWidgets('múltiplos 401 chamam onSessionExpired uma única vez', (
      tester,
    ) async {
      var expired = 0;
      final controller = PatientProfileFormController(
        _api((_) async => http.Response('', 401)),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: PatientProfileFormPage(
            controller: controller,
            currentPatient: const Patient(
              nomeCompleto: 'Ana Souza',
              cpf: '',
              telefone: '',
              dataNascimento: null,
              sexo: '',
              estadoCivil: '',
              endereco: PatientAddress(),
              email: 'ana@example.com',
            ),
            onSaved: () {},
            onSessionExpired: () => expired++,
          ),
        ),
      );

      await controller.submit(_request);
      await tester.pump();
      await controller.submit(_request);
      await tester.pump();

      expect(expired, 1);
    });
  });
}
