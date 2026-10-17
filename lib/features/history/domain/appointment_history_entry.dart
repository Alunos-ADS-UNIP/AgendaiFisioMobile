import '../../../core/models/appointment_status.dart';

/// Consulta passada exibida no histórico. `dateTime` já está no fuso local.
class AppointmentHistoryEntry {
  const AppointmentHistoryEntry({
    required this.appointmentId,
    required this.dateTime,
    required this.professionalName,
    required this.status,
  });

  final String appointmentId;
  final DateTime dateTime;
  final String professionalName;
  final AppointmentStatus status;
}

/// Uma página do histórico, na ordem devolvida pela API (mais recente primeiro).
class AppointmentHistoryPage {
  const AppointmentHistoryPage({
    required this.items,
    required this.currentPage,
    required this.totalPages,
  });

  final List<AppointmentHistoryEntry> items;
  final int currentPage;
  final int totalPages;

  bool get isLastPage => items.isEmpty || currentPage >= totalPages;
}
