import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/input_masks.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_secondary_button.dart';
import '../../domain/appointment_repository.dart';
import '../../domain/professional.dart';

/// Perfil do profissional antes de agendar, com os mesmos dados mostrados no
/// detalhe da consulta. Fecha com `true` quando o paciente escolhe seguir com o
/// agendamento; "Voltar" fecha sem escolher nada.
class ProfessionalInfoPage extends StatefulWidget {
  const ProfessionalInfoPage({
    required this.repository,
    required this.professional,
    required this.specialtyName,
    super.key,
  });

  final AppointmentRepository repository;
  final Professional professional;
  final String specialtyName;

  @override
  State<ProfessionalInfoPage> createState() => _ProfessionalInfoPageState();
}

class _ProfessionalInfoPageState extends State<ProfessionalInfoPage> {
  late final Future<String> _email = _loadEmail();

  Future<String> _loadEmail() async {
    final repository = widget.repository;
    final directory = repository is ProfessionalContactDirectory
        ? repository as ProfessionalContactDirectory
        : null;
    if (directory == null) return '';
    try {
      return await directory.fetchProfessionalEmail(widget.professional.id);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Perfil do profissional')),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _InfoRow(
                  label: 'Fisioterapeuta',
                  value: _orDash(widget.professional.name),
                ),
                _InfoRow(
                  label: 'Especialização',
                  value: _orDash(widget.specialtyName),
                ),
                _InfoRow(
                  label: 'CREFITO',
                  value: _orDash(
                    InputMasks.displayCrefito(widget.professional.crefito),
                  ),
                ),
                FutureBuilder<String>(
                  future: _email,
                  builder: (context, snapshot) => _InfoRow(
                    label: 'E-mail para contato',
                    value: _orDash(snapshot.data ?? ''),
                  ),
                ),
                _InfoRow(
                  label: 'Descrição',
                  value: widget.professional.bio.trim().isEmpty
                      ? 'Sem descrição cadastrada.'
                      : widget.professional.bio,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppPrimaryButton(
                  label: 'Agendar',
                  onPressed: () => Navigator.pop(context, true),
                ),
                const SizedBox(height: AppSpacing.xs),
                AppSecondaryButton(
                  label: 'Voltar',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  static String _orDash(String value) => value.trim().isEmpty ? '—' : value;
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ],
    ),
  );
}
