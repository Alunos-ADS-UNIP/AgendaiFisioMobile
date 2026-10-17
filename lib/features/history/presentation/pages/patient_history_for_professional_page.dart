import 'package:flutter/material.dart';

import '../../domain/history_repository.dart';
import '../controllers/history_controller.dart';
import '../widgets/appointment_history_list.dart';

/// Histórico de um paciente visto pelo profissional. O `patientId` deve vir de
/// um fluxo autorizado (por exemplo, um agendamento do próprio profissional) e
/// nunca é exibido nem digitado. A API responde 404 quando não há vínculo.
class PatientHistoryForProfessionalPage extends StatefulWidget {
  const PatientHistoryForProfessionalPage({
    required this.repository,
    required this.patientId,
    required this.patientName,
    super.key,
  });

  final HistoryRepository repository;
  final String patientId;
  final String patientName;

  @override
  State<PatientHistoryForProfessionalPage> createState() =>
      _PatientHistoryForProfessionalPageState();
}

class _PatientHistoryForProfessionalPageState
    extends State<PatientHistoryForProfessionalPage> {
  late final HistoryController _controller = HistoryController(
    loadPage: (page, pageSize) => widget.repository.fetchPatientHistory(
      patientId: widget.patientId,
      page: page,
      pageSize: pageSize,
    ),
  );

  @override
  void initState() {
    super.initState();
    _controller.loadFirstPage();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.patientName.isEmpty
              ? 'Histórico do paciente'
              : 'Histórico de ${widget.patientName}',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: AppointmentHistoryList(
        controller: _controller,
        emptyTitle: 'Nenhuma consulta passada',
        emptyMessage: 'Este paciente ainda não tem consultas no histórico.',
      ),
    );
  }
}
