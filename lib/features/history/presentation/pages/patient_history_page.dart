import 'package:flutter/material.dart';

import '../../domain/history_repository.dart';
import '../controllers/history_controller.dart';
import '../widgets/appointment_history_list.dart';

/// Histórico do paciente logado. Usa somente GET
/// /api/paciente/me/historico-consultas; nunca recebe nem envia o próprio ID.
class PatientHistoryPage extends StatefulWidget {
  const PatientHistoryPage({required this.repository, super.key});

  final HistoryRepository repository;

  @override
  State<PatientHistoryPage> createState() => _PatientHistoryPageState();
}

class _PatientHistoryPageState extends State<PatientHistoryPage> {
  late final HistoryController _controller = HistoryController(
    loadPage: (page, pageSize) =>
        widget.repository.fetchMyHistory(page: page, pageSize: pageSize),
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
      appBar: AppBar(title: const Text('Histórico de consultas')),
      body: AppointmentHistoryList(
        controller: _controller,
        emptyTitle: 'Nenhuma consulta realizada',
        emptyMessage:
            'Suas consultas passadas aparecerão aqui depois do atendimento.',
      ),
    );
  }
}
