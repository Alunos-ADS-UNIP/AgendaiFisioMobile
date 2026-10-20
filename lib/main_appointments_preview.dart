import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'development/appointment_preview_repository.dart';
import 'features/appointments/presentation/pages/appointments_page.dart';

void main() {
  final repository = AppointmentPreviewRepository();
  runApp(
    MaterialApp(
      title: 'AgendaiFisio — Agenda',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      builder: (context, child) => Banner(
        message: 'DEMO',
        location: BannerLocation.topEnd,
        child: child!,
      ),
      home: AppointmentsPage(repository: repository),
    ),
  );
}
