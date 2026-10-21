import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'development/appointment_preview_repository.dart';
import 'features/appointments/presentation/pages/patient_area_page.dart';

void main() {
  final repository = AppointmentPreviewRepository();
  runApp(
    MaterialApp(
      title: 'AgendaiFisio — Agenda',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => Banner(
        message: 'DEMO',
        location: BannerLocation.topEnd,
        child: child!,
      ),
      home: PatientAreaPage(repository: repository, initialIndex: 2),
    ),
  );
}
