import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../development/component_catalog_page.dart';
import '../features/appointments/data/appointment_api_repository.dart';
import '../features/appointments/domain/appointment_repository.dart';
import '../features/appointments/presentation/pages/patient_area_page.dart';
import '../features/auth/data/auth_api.dart';
import '../features/auth/data/session_storage.dart';
import '../features/auth/domain/auth_session.dart';
import '../features/auth/presentation/controllers/session_controller.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/role_home_page.dart';
import '../features/history/data/history_api_repository.dart';
import '../features/history/domain/history_repository.dart';
import '../features/patients/data/patient_api.dart';
import '../features/patients/presentation/controllers/patient_profile_controller.dart';
import '../features/patients/presentation/controllers/patient_profile_form_controller.dart';
import '../features/patients/presentation/controllers/patient_register_controller.dart';
import '../features/patients/presentation/pages/patient_profile_form_page.dart';
import '../features/patients/presentation/pages/patient_profile_page.dart';
import '../features/patients/presentation/pages/patient_register_page.dart';
import '../features/professional_profile/data/professional_profile_api.dart';
import '../features/professional_profile/presentation/controllers/professional_profile_controller.dart';
import '../features/professional_profile/presentation/controllers/professional_register_controller.dart';
import '../features/professional_profile/presentation/pages/professional_profile_page.dart';
import '../features/professional_profile/presentation/pages/professional_register_page.dart';

class AgendaiFisioApp extends StatefulWidget {
  const AgendaiFisioApp({
    this.sessionController,
    this.patientRepository,
    this.historyRepository,
    this.patientName,
    this.patientProfileBuilder,
    this.professionalProfileApi,
    this.showComponentCatalog = false,
    super.key,
  });

  final SessionController? sessionController;

  /// Injeções mantidas para previews e testes isolados da área do paciente.
  final AppointmentRepository? patientRepository;
  final HistoryRepository? historyRepository;
  final String? patientName;
  final WidgetBuilder? patientProfileBuilder;
  final ProfessionalProfileApi? professionalProfileApi;
  final bool showComponentCatalog;

  @override
  State<AgendaiFisioApp> createState() => _AgendaiFisioAppState();
}

class _AgendaiFisioAppState extends State<AgendaiFisioApp> {
  SessionController? _sessionController;
  ApiClient? _apiClient;
  PatientApi? _patientApi;
  ProfessionalProfileApi? _professionalProfileApi;
  AppointmentApiRepository? _appointmentRepository;
  HistoryApiRepository? _historyRepository;
  bool _ownsSessionController = false;

  @override
  void initState() {
    super.initState();
    if (widget.showComponentCatalog || widget.patientRepository != null) return;

    _sessionController = widget.sessionController;
    if (_sessionController == null) {
      _ownsSessionController = true;
      _sessionController = SessionController(
        authGateway: AuthApi(baseUrl: ApiConfig.baseUrl),
        storage: SecureSessionStorage(),
      );
    }

    final session = _sessionController!;
    _apiClient = ApiClient(
      baseUrl: ApiConfig.baseUrl,
      authHeaderProvider: session.tokenProvider,
    );
    _patientApi = PatientApi(_apiClient!);
    _professionalProfileApi =
        widget.professionalProfileApi ?? ProfessionalProfileApi(_apiClient!);
    _appointmentRepository = AppointmentApiRepository(
      baseUri: Uri.parse(ApiConfig.baseUrl),
      tokenProvider: session.tokenProvider,
      onUnauthorized: session.expireSession,
    );
    _historyRepository = HistoryApiRepository(_historyGet);

    if (session.status == SessionStatus.restoring) {
      unawaited(session.restore());
    }
  }

  @override
  void dispose() {
    if (_ownsSessionController) _sessionController?.dispose();
    _appointmentRepository?.dispose();
    super.dispose();
  }

  Future<HistoryHttpResponse> _historyGet(
    String path,
    Map<String, String> queryParameters,
  ) async {
    final token = await _sessionController!.tokenProvider();
    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}$path')
              .replace(queryParameters: queryParameters),
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 401) {
      await _sessionController!.expireSession();
    }
    return HistoryHttpResponse(
      statusCode: response.statusCode,
      body: response.body,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgendaiFisio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: _home(),
    );
  }

  Widget _home() {
    if (widget.showComponentCatalog) return const ComponentCatalogPage();
    if (widget.patientRepository != null) {
      return PatientAreaPage(
        repository: widget.patientRepository!,
        historyRepository: widget.historyRepository,
        patientName: widget.patientName,
        profileBuilder: widget.patientProfileBuilder,
      );
    }

    final session = _sessionController!;
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => switch (session.status) {
        SessionStatus.restoring => const _SessionSplash(),
        SessionStatus.unauthenticated ||
        SessionStatus.authenticating => LoginPage(
          controller: session,
          onCreateAccount: () => _openRegistration(context),
        ),
        SessionStatus.authenticated => _authenticatedHome(session),
      },
    );
  }

  Widget _authenticatedHome(SessionController session) {
    final user = session.user!;
    if (user.role == UserRole.professional) {
      return _ProfessionalHome(
        key: ValueKey(user.userId),
        api: _professionalProfileApi!,
        onLogout: () => unawaited(session.logout()),
      );
    }
    if (user.role != UserRole.patient) {
      return RoleHomePage(
        user: user,
        onLogout: () => unawaited(session.logout()),
      );
    }
    return PatientAreaPage(
      repository: _appointmentRepository!,
      historyRepository: _historyRepository,
      patientName: user.email.split('@').first,
      profileBuilder: (context) => _buildPatientProfile(context, session),
    );
  }

  Widget _buildPatientProfile(BuildContext context, SessionController session) {
    final controller = PatientProfileController(_patientApi!);
    return PatientProfilePage(
      controller: controller,
      onLogout: () => unawaited(session.logout()),
      onEdit: (patient) async {
        final saved = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (routeContext) => PatientProfileFormPage(
              controller: PatientProfileFormController(_patientApi!),
              currentPatient: patient,
              onSaved: () => Navigator.of(routeContext).pop(true),
            ),
          ),
        );
        if (saved == true) await controller.load();
      },
    );
  }

  Future<void> _openRegistration(BuildContext context) async {
    final role = await showModalBottomSheet<UserRole>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Sou paciente'),
              onTap: () => Navigator.of(sheetContext).pop(UserRole.patient),
            ),
            ListTile(
              leading: const Icon(Icons.medical_services_outlined),
              title: const Text('Sou fisioterapeuta'),
              onTap: () =>
                  Navigator.of(sheetContext).pop(UserRole.professional),
            ),
          ],
        ),
      ),
    );
    if (role == null || !context.mounted) return;
    if (role == UserRole.professional) {
      final controller = ProfessionalRegisterController(
        _professionalProfileApi!,
      );
      try {
        final registered = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (routeContext) => ProfessionalRegisterPage(
              controller: controller,
              onRegistered: () => Navigator.of(routeContext).pop(true),
              onGoToLogin: () => Navigator.of(routeContext).pop(false),
            ),
          ),
        );
        if (registered == true && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conta criada. Entre para completar seu perfil.'),
            ),
          );
        }
      } finally {
        controller.dispose();
      }
      return;
    }
    final registered = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (routeContext) => PatientRegisterPage(
          controller: PatientRegisterController(_patientApi!),
          onRegistered: () => Navigator.of(routeContext).pop(true),
          onGoToLogin: () => Navigator.of(routeContext).pop(false),
        ),
      ),
    );
    if (registered == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conta criada. Agora você já pode entrar.'),
        ),
      );
    }
  }
}

class _ProfessionalHome extends StatefulWidget {
  const _ProfessionalHome({
    required this.api,
    required this.onLogout,
    super.key,
  });

  final ProfessionalProfileApi api;
  final VoidCallback onLogout;

  @override
  State<_ProfessionalHome> createState() => _ProfessionalHomeState();
}

class _ProfessionalHomeState extends State<_ProfessionalHome> {
  late final ProfessionalProfileController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ProfessionalProfileController(widget.api);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ProfessionalProfilePage(
    controller: _controller,
    onLogout: widget.onLogout,
  );
}

class _SessionSplash extends StatelessWidget {
  const _SessionSplash();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.primaryLight,
            child: Icon(
              Icons.health_and_safety_rounded,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 20),
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Preparando seu acesso...'),
        ],
      ),
    ),
  );
}
