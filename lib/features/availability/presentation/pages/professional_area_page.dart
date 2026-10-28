import 'package:flutter/material.dart';

import '../../../appointments/domain/appointment_repository.dart';
import '../../../appointments/presentation/pages/appointments_page.dart';
import '../../domain/availability_repository.dart';
import 'professional_availability_page.dart';
import 'professional_home_page.dart';

/// Navegação do fisioterapeuta (menu inferior), no mesmo padrão da área do
/// paciente. Só tem opções válidas para ele: o fisioterapeuta NÃO agenda
/// consultas, então não existe a opção "Agendar".
///
/// Pacientes ficará aqui quando a tela existir.
class ProfessionalAreaPage extends StatefulWidget {
  const ProfessionalAreaPage({
    required this.repository,
    required this.availabilityRepository,
    required this.professionalId,
    required this.profileBuilder,
    this.professionalName,
    super.key,
  });

  final AppointmentRepository repository;
  final AvailabilityRepository availabilityRepository;
  final String professionalId;
  final WidgetBuilder profileBuilder;
  final String? professionalName;

  @override
  State<ProfessionalAreaPage> createState() => _ProfessionalAreaPageState();
}

class _ProfessionalAreaPageState extends State<ProfessionalAreaPage> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: switch (_selected) {
      0 => ProfessionalHomePage(
        repository: widget.repository,
        professionalName: widget.professionalName,
        onOpenAgenda: () => setState(() => _selected = 1),
      ),
      1 => AppointmentsPage(
        repository: widget.repository,
        title: 'Agenda',
        professionalView: true,
      ),
      2 => ProfessionalAvailabilityPage(
        repository: widget.availabilityRepository,
        professionalId: widget.professionalId,
      ),
      _ => widget.profileBuilder(context),
    },
    bottomNavigationBar: NavigationBar(
      selectedIndex: _selected,
      onDestinationSelected: (index) => setState(() => _selected = index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Início',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: 'Agenda',
        ),
        NavigationDestination(
          icon: Icon(Icons.schedule_outlined),
          selectedIcon: Icon(Icons.schedule),
          label: 'Grade',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    ),
  );
}
