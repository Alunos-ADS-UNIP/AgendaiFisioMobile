import '../../../../core/models/appointment_status.dart';
import '../../domain/appointment_history_entry.dart';

/// Item de HistoricoConsultaDTO, exatamente como devolvido pela API.
class HistoryItemDto {
  const HistoryItemDto({
    required this.agendamentoId,
    required this.dataHora,
    required this.profissionalId,
    required this.profissionalNome,
    required this.status,
  });

  factory HistoryItemDto.fromJson(Map<String, dynamic> json) {
    return HistoryItemDto(
      agendamentoId: json['agendamentoId'] as String,
      dataHora: DateTime.parse(json['dataHora'] as String),
      profissionalId: json['profissionalId'] as String,
      profissionalNome: json['profissionalNome'] as String? ?? '',
      status: json['status'] as String,
    );
  }

  final String agendamentoId;
  final DateTime dataHora;
  final String profissionalId;
  final String profissionalNome;
  final String status;

  AppointmentHistoryEntry toEntry() {
    return AppointmentHistoryEntry(
      appointmentId: agendamentoId,
      dateTime: dataHora.toLocal(),
      professionalName: profissionalNome,
      status: parseApiStatus(status),
    );
  }
}

/// `PagedResultDTO<HistoricoConsultaDTO>`, exatamente como devolvido pela API.
class HistoryPageDto {
  const HistoryPageDto({
    required this.itens,
    required this.totalRegistros,
    required this.paginaAtual,
    required this.tamanhoPagina,
    required this.totalPaginas,
  });

  factory HistoryPageDto.fromJson(Map<String, dynamic> json) {
    return HistoryPageDto(
      itens: (json['itens'] as List<dynamic>? ?? const [])
          .map((item) => HistoryItemDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalRegistros: json['totalRegistros'] as int,
      paginaAtual: json['paginaAtual'] as int,
      tamanhoPagina: json['tamanhoPagina'] as int,
      totalPaginas: json['totalPaginas'] as int,
    );
  }

  final List<HistoryItemDto> itens;
  final int totalRegistros;
  final int paginaAtual;
  final int tamanhoPagina;
  final int totalPaginas;

  AppointmentHistoryPage toPage() {
    return AppointmentHistoryPage(
      items: itens.map((item) => item.toEntry()).toList(),
      currentPage: paginaAtual,
      totalPages: totalPaginas,
    );
  }
}

/// Converte os valores de Constants/StatusAgendamento.cs do backend.
AppointmentStatus parseApiStatus(String value) {
  return switch (value) {
    'Agendado' => AppointmentStatus.scheduled,
    'Confirmado' => AppointmentStatus.confirmed,
    'Cancelado' => AppointmentStatus.cancelled,
    'Concluido' => AppointmentStatus.completed,
    _ => throw FormatException('Status de agendamento desconhecido: $value'),
  };
}
