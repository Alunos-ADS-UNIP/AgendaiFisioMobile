import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/theme/app_theme.dart';
import '../development/component_catalog_page.dart';
import '../features/appointments/domain/appointment_repository.dart';
import '../features/appointments/presentation/pages/patient_area_page.dart';
import '../features/history/domain/history_repository.dart';

class AgendaiFisioApp extends StatelessWidget {
  const AgendaiFisioApp({
    this.patientRepository,
    this.historyRepository,
    this.patientName,
    this.patientProfileBuilder,
    super.key,
  });

  /// Injected by the authenticated session once the shared login feature is wired.
  final AppointmentRepository? patientRepository;
  final HistoryRepository? historyRepository;
  final String? patientName;
  final WidgetBuilder? patientProfileBuilder;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgendaiFisio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: patientRepository == null
          ? const ComponentCatalogPage()
          : PatientAreaPage(
              repository: patientRepository!,
              historyRepository: historyRepository,
              patientName: patientName,
              profileBuilder: patientProfileBuilder,
            ),
    );
  }
}
