import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loading_skeleton.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../domain/availability_failure.dart';
import '../../domain/availability_models.dart';
import '../../domain/availability_repository.dart';
import '../controllers/availability_controller.dart';
import '../widgets/weekly_schedule.dart';
import 'weekly_schedule_form_page.dart';

/// Grade semanal do fisioterapeuta: carregando, indisponível, erro, vazio e
/// grade. Somente leitura; a edição virá na weekly_schedule_form_page.
class ProfessionalAvailabilityPage extends StatefulWidget {
  const ProfessionalAvailabilityPage({required this.repository, super.key});

  final AvailabilityRepository repository;

  @override
  State<ProfessionalAvailabilityPage> createState() =>
      _ProfessionalAvailabilityPageState();
}

class _ProfessionalAvailabilityPageState
    extends State<ProfessionalAvailabilityPage> {
  late final AvailabilityController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AvailabilityController(repository: widget.repository)..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _edit() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WeeklyScheduleFormPage(
          repository: widget.repository,
          initial: _controller.schedule ?? WeeklySchedule.empty(),
        ),
      ),
    );
    if (saved == true && mounted) await _controller.load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Grade de horários'),
      actions: [
        ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => IconButton(
            tooltip: 'Editar grade',
            onPressed: _controller.isLoading ? null : _edit,
            icon: const Icon(Icons.edit_calendar_outlined),
          ),
        ),
      ],
    ),
    body: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) =>
          RefreshIndicator(onRefresh: _controller.load, child: _body()),
    ),
  );

  Widget _body() {
    final c = _controller;
    final Widget child;
    if (c.isLoading) {
      child = const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: AppLoadingSkeleton(lines: 4),
      );
    } else if (c.isUnavailable) {
      child = const EmptyState(
        title: 'Grade ainda não disponível',
        message: 'Esta funcionalidade será liberada quando o sistema estiver pronto.',
        icon: Icons.construction_outlined,
      );
    } else if (c.failure != null) {
      child = ErrorState(
        message: switch (c.failure!) {
          AvailabilityFailure.network =>
            'Verifique sua conexão e tente novamente.',
          AvailabilityFailure.unauthorized =>
            'Sua sessão expirou. Entre novamente.',
          _ => 'Não foi possível carregar sua grade.',
        },
        onRetry: c.load,
      );
    } else if (c.isEmpty) {
      child = const EmptyState(
        title: 'Nenhum dia configurado',
        message: 'Quando você definir dias e turnos, eles aparecem aqui.',
        icon: Icons.calendar_month_outlined,
      );
    } else {
      child = Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: WeeklyScheduleView(schedule: c.schedule!),
      );
    }
    // ListView permite puxar para atualizar mesmo nos estados curtos.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [child],
    );
  }
}
