import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/input_masks.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_secondary_button.dart';
import '../../../../core/widgets/info_card.dart';
import '../../domain/appointment_repository.dart';
import '../../domain/professional.dart';

/// Perfil do profissional antes de agendar, com o mesmo desenho do detalhe da
/// consulta. Fecha com `true` quando o paciente escolhe agendar; "Voltar"
/// fecha sem escolher nada.
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
            child: FutureBuilder<String>(
              future: _email,
              builder: (context, snapshot) => ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  Text(
                    'Informações do fisioterapeuta',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  InfoLine(
                    icon: Icons.person_outline,
                    label: 'Fisioterapeuta',
                    value: _orDash(widget.professional.name),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  InfoLine(
                    icon: Icons.medical_services_outlined,
                    label: 'Especialização',
                    value: _orDash(widget.specialtyName),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  InfoLine(
                    icon: Icons.badge_outlined,
                    label: 'CREFITO',
                    value: _orDash(
                      InputMasks.displayCrefito(widget.professional.crefito),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  InfoLine(
                    icon: Icons.email_outlined,
                    label: 'E-mail para contato',
                    value: _orDash(snapshot.data ?? ''),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  InfoLine(
                    icon: Icons.description_outlined,
                    label: 'Descrição',
                    value: widget.professional.bio.trim().isEmpty
                        ? 'Sem descrição cadastrada.'
                        : widget.professional.bio,
                  ),
                ],
              ),
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
