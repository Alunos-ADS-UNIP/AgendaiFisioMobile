import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../../history/domain/history_repository.dart';
import '../../domain/appointment_repository.dart';
import 'appointments_page.dart';
import 'new_appointment_page.dart';
import 'patient_home_page.dart';

/// Navegação do paciente. O perfil real é fornecido pelo módulo responsável.
class PatientAreaPage extends StatefulWidget {
  const PatientAreaPage({
    required this.repository,
    this.historyRepository,
    this.patientName,
    this.profileBuilder,
    this.initialIndex = 0,
    super.key,
  }) : assert(initialIndex == 0 || initialIndex == 2 || initialIndex == 3);

  final AppointmentRepository repository;
  final HistoryRepository? historyRepository;
  final String? patientName;
  final WidgetBuilder? profileBuilder;
  final int initialIndex;

  @override
  State<PatientAreaPage> createState() => _PatientAreaPageState();
}

class _PatientAreaPageState extends State<PatientAreaPage> {
  late int _selected = widget.initialIndex;
  int _revision = 0;

  Future<void> _select(int index) async {
    if (index == 1) {
      final result = await Navigator.of(context).push<Object?>(
        MaterialPageRoute(
          builder: (_) => NewAppointmentPage(repository: widget.repository),
        ),
      );
      if (!mounted) return;
      if (result == completeProfileResult) {
        setState(() => _selected = 3);
      } else if (result == true) {
        setState(() {
          _selected = 2;
          _revision++;
        });
      }
      return;
    }
    setState(() => _selected = index);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: switch (_selected) {
      0 => PatientHomePage(
        key: ValueKey('home-$_revision'),
        repository: widget.repository,
        historyRepository: widget.historyRepository,
        patientName: widget.patientName,
      ),
      2 => AppointmentsPage(
        key: ValueKey('agenda-$_revision'),
        repository: widget.repository,
      ),
      _ =>
        widget.profileBuilder?.call(context) ??
            Scaffold(
              appBar: AppBar(title: const Text('Meu perfil')),
              body: SingleChildScrollView(
                child: EmptyState(
                  title: 'Perfil ainda não conectado',
                  message: 'Esta área aguarda a integração do módulo de perfil do paciente.',
                  icon: Icons.person_outline,
                  actionLabel: 'Voltar à agenda',
                  onAction: () => _select(2),
                ),
              ),
            ),
    },
    bottomNavigationBar: NavigationBar(
      selectedIndex: _selected,
      onDestinationSelected: _select,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Início',
        ),
        NavigationDestination(
          icon: Icon(Icons.add_circle_outline),
          label: 'Agendar',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: 'Agenda',
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
