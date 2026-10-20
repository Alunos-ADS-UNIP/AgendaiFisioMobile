import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../development/component_catalog_page.dart';
import '../features/appointments/domain/appointment_repository.dart';
import '../features/appointments/presentation/pages/patient_home_page.dart';
import '../features/history/domain/history_repository.dart';

class AgendaiFisioApp extends StatelessWidget {
  const AgendaiFisioApp({
    this.patientRepository,
    this.historyRepository,
    this.patientName,
    super.key,
  });

  /// Injected by the authenticated session once the shared login feature is wired.
  final AppointmentRepository? patientRepository;
  final HistoryRepository? historyRepository;
  final String? patientName;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgendaiFisio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: patientRepository == null
          ? const ComponentCatalogPage()
          : PatientHomePage(
              repository: patientRepository!,
              historyRepository: historyRepository,
              patientName: patientName,
            ),
    );
  }
}
