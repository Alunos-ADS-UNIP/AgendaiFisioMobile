import 'dart:async';

import 'package:agendaifisiomobile/core/models/appointment_status.dart';
import 'package:agendaifisiomobile/features/history/domain/appointment_history_entry.dart';
import 'package:agendaifisiomobile/features/history/domain/history_failure.dart';
import 'package:agendaifisiomobile/features/history/domain/history_repository.dart';

AppointmentHistoryEntry fakeEntry(int index, {String? professionalName}) {
  return AppointmentHistoryEntry(
    appointmentId: 'agendamento-$index',
    dateTime: DateTime(2026, 9, 30).subtract(Duration(days: index)),
    professionalName: professionalName ?? 'Profissional $index',
    status: AppointmentStatus.completed,
  );
}

/// Simula a paginação da API sobre uma lista já ordenada.
class FakeHistoryRepository implements HistoryRepository {
  FakeHistoryRepository({this.entries = const [], this.failure});

  final List<AppointmentHistoryEntry> entries;
  HistoryFailure? failure;
  final List<int> requestedPages = [];
  final List<String?> requestedPatientIds = [];

  /// Quando definido, as respostas só chegam após completar o completer.
  Completer<void>? gate;

  @override
  Future<AppointmentHistoryPage> fetchMyHistory({
    required int page,
    required int pageSize,
  }) {
    requestedPatientIds.add(null);
    return _page(page, pageSize);
  }

  @override
  Future<AppointmentHistoryPage> fetchPatientHistory({
    required String patientId,
    required int page,
    required int pageSize,
  }) {
    requestedPatientIds.add(patientId);
    return _page(page, pageSize);
  }

  Future<AppointmentHistoryPage> _page(int page, int pageSize) async {
    requestedPages.add(page);
    await gate?.future;
    final currentFailure = failure;
    if (currentFailure != null) throw HistoryException(currentFailure);

    final start = (page - 1) * pageSize;
    final totalPages = (entries.length / pageSize).ceil();
    return AppointmentHistoryPage(
      items: start >= entries.length
          ? const []
          : entries.skip(start).take(pageSize).toList(),
      currentPage: page,
      totalPages: totalPages,
    );
  }
}
