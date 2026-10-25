import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_secondary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/professional_card.dart';
import '../../domain/appointment.dart';
import '../../domain/appointment_failure.dart';
import '../../domain/appointment_repository.dart';
import '../../domain/professional.dart';
import '../../domain/specialty.dart';
import '../widgets/appointment_specialty_picker_sheet.dart';
import 'appointment_created_page.dart';

class NewAppointmentPage extends StatefulWidget {
  const NewAppointmentPage({
    required this.repository,
    this.initialProfessionalId,
    super.key,
  });

  final AppointmentRepository repository;
  final String? initialProfessionalId;

  @override
  State<NewAppointmentPage> createState() => _NewAppointmentPageState();
}

class _NewAppointmentPageState extends State<NewAppointmentPage> {
  static const _availableHours = [9, 10, 11, 12, 13, 14, 15, 16, 17, 18];

  final _notesController = TextEditingController();
  List<Specialty> _specialties = const [];
  List<Professional> _professionals = const [];
  Specialty? _specialty;
  Professional? _professional;
  DateTime? _day;
  TimeOfDay? _time;
  bool _loading = true;
  bool _loadingProfessionals = false;
  bool _submitting = false;
  int _step = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final specialties = await widget.repository.fetchSpecialties();
      Professional? professional;
      if (widget.initialProfessionalId != null) {
        professional = await widget.repository.fetchProfessional(
          widget.initialProfessionalId!,
        );
      }
      if (!mounted) return;
      setState(() {
        _specialties = specialties;
        _professional = professional;
        _specialty = specialties
            .where((item) => item.id == professional?.specialtyId)
            .firstOrNull;
        _step = professional == null ? 0 : 2;
        _loading = false;
        _error = null;
      });
      if (professional == null &&
          specialties.isNotEmpty &&
          _specialty == null) {
        // The patient chooses explicitly; do not silently select the first item.
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Não foi possível carregar especialidades e profissionais.';
        });
      }
    }
  }

  Future<void> _chooseSpecialty() async {
    final specialty = await showModalBottomSheet<Specialty>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          AppointmentSpecialtyPickerSheet(repository: widget.repository),
    );
    if (specialty == null || !mounted) return;
    setState(() {
      _specialty = specialty;
      _professional = null;
      _professionals = const [];
      _step = 1;
      _error = null;
    });
    await _loadProfessionals(specialty.id);
  }

  Future<void> _loadProfessionals(String specialtyId) async {
    setState(() {
      _loadingProfessionals = true;
      _error = null;
    });
    try {
      final items = await widget.repository.fetchProfessionals(
        specialtyId: specialtyId,
        active: true,
        page: 1,
        pageSize: 100,
      );
      if (mounted) {
        setState(
          () => _professionals = items.where((item) => item.isActive).toList(),
        );
      }
    } on AppointmentException catch (error) {
      if (mounted) setState(() => _error = error.userMessage);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível carregar os profissionais.');
      }
    } finally {
      if (mounted) setState(() => _loadingProfessionals = false);
    }
  }

  Future<void> _selectDay() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _day ?? now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2, 12, 31),
      helpText: 'Escolha o dia da consulta',
    );
    if (picked != null && mounted) {
      setState(() {
        _day = picked;
        _error = null;
      });
    }
  }

  void _selectTime(int hour) {
    setState(() {
      _time = TimeOfDay(hour: hour, minute: 0);
      _error = null;
    });
  }

  bool _isHourInFuture(int hour) {
    if (_day == null) return false;
    final dateTime = DateTime(_day!.year, _day!.month, _day!.day, hour);
    return dateTime.isAfter(DateTime.now());
  }

  DateTime? get _selectedDateTime {
    if (_day == null || _time == null) return null;
    return DateTime(
      _day!.year,
      _day!.month,
      _day!.day,
      _time!.hour,
      _time!.minute,
    );
  }

  bool get _isDateTimeValid {
    final selected = _selectedDateTime;
    return selected != null && selected.isAfter(DateTime.now());
  }

  Future<void> _submit() async {
    final selected = _selectedDateTime;
    if (_professional == null ||
        selected == null ||
        !selected.isAfter(DateTime.now())) {
      setState(() => _error = 'Escolha um profissional e um horário futuro.');
      return;
    }
    if (_notesController.text.trim().length > 1000) {
      setState(() => _error = 'As observações devem ter até 1000 caracteres.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final appointment = await widget.repository.createAppointment(
        professionalId: _professional!.id,
        dateTime: selected,
        observations: _notesController.text,
      );
      if (!mounted) return;
      final summary = Appointment(
        id: appointment.id,
        professionalId: appointment.professionalId,
        professionalName: appointment.professionalName.isEmpty
            ? _professional!.name
            : appointment.professionalName,
        specialtyName: _professional!.specialtyName.isEmpty
            ? (_specialty?.name ?? '')
            : _professional!.specialtyName,
        dateTime: appointment.dateTime,
        status: appointment.status,
        observations: appointment.observations,
      );
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => AppointmentCreatedPage(
            repository: widget.repository,
            appointment: summary,
          ),
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } on AppointmentException catch (error) {
      if (mounted) setState(() => _error = error.userMessage);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Não foi possível salvar. Sua seleção foi mantida; tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Novo agendamento'),
      leading: IconButton(
        tooltip: 'Voltar',
        icon: const Icon(Icons.arrow_back),
        onPressed: _submitting
            ? null
            : () => _step == 0
                  ? Navigator.pop(context)
                  : setState(() {
                      _step--;
                      _error = null;
                    }),
      ),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null && _specialties.isEmpty
        ? ErrorState(message: _error!, onRetry: _loadInitialData)
        : SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                104,
              ),
              children: [
                Text(
                  'Etapa ${_step + 1} de 3',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                LinearProgressIndicator(value: (_step + 1) / 3),
                const SizedBox(height: AppSpacing.md),
                if (_step == 0) _specialtyStep(context),
                if (_step == 1) _professionalStep(context),
                if (_step == 2) _reviewStep(context),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    floatingActionButton: _loading || (_error != null && _specialties.isEmpty)
        ? null
        : SizedBox(
            width: MediaQuery.sizeOf(context).width - (AppSpacing.md * 2),
            child: Material(
              elevation: 6,
              color: Colors.transparent,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              child: _actionButton(),
            ),
          ),
  );

  Widget _actionButton() {
    if (_step == 2) {
      return AppPrimaryButton(
        label: 'Confirmar agendamento',
        icon: Icons.check,
        isLoading: _submitting,
        onPressed: _isDateTimeValid ? _submit : null,
      );
    }

    return AppPrimaryButton(
      label: _step == 0 ? 'Escolher especialidade' : 'Escolher data e horário',
      onPressed: _canContinue ? _continue : null,
    );
  }

  bool get _canContinue =>
      _step == 0 ? _specialty != null : _professional != null;

  Future<void> _continue() async {
    if (_step == 0) {
      if (_specialty == null) return;
      setState(() => _step = 1);
      await _loadProfessionals(_specialty!.id);
    } else if (_professional != null) {
      setState(() {
        _step = 2;
        _error = null;
      });
    }
  }

  Widget _specialtyStep(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Qual especialidade você procura?',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: AppSpacing.sm),
      AppSecondaryButton(
        onPressed: _chooseSpecialty,
        icon: Icons.spa_outlined,
        label: _specialty?.name ?? 'Selecionar especialidade',
      ),
      if (_specialties.isEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text('Nenhuma especialidade disponível no momento.'),
        ),
    ],
  );

  Widget _professionalStep(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Escolha o profissional',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      Text(_specialty?.name ?? ''),
      const SizedBox(height: AppSpacing.sm),
      if (_loadingProfessionals)
        const Center(child: CircularProgressIndicator())
      else if (_professionals.isEmpty)
        const Text('Não há profissionais ativos para essa especialidade.')
      else
        ..._professionals.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ProfessionalCard(
              name: item.name,
              isSelected: _professional?.id == item.id,
              specialty: item.specialtyName.isEmpty
                  ? (_specialty?.name ?? '')
                  : item.specialtyName,
              crefito: item.crefito,
              isActive: item.isActive,
              onTap: () => setState(() {
                _professional = item;
                _error = null;
              }),
            ),
          ),
        ),
    ],
  );

  Widget _reviewStep(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Revise os dados', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppSpacing.sm),
      ListTile(
        leading: const Icon(Icons.spa_outlined),
        title: Text(_specialty?.name ?? 'Especialidade'),
      ),
      ListTile(
        leading: const Icon(Icons.person_outline),
        title: Text(_professional?.name ?? 'Profissional'),
        subtitle: Text(_professional?.crefito ?? ''),
      ),
      AppSecondaryButton(
        onPressed: _selectDay,
        icon: Icons.calendar_today_outlined,
        label: _day == null
            ? 'Selecionar data'
            : MaterialLocalizations.of(context).formatMediumDate(_day!),
      ),
      const SizedBox(height: AppSpacing.md),
      Text('Escolha o horário', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: AppSpacing.xs),
      Text(
        _day == null
            ? 'Selecione uma data para liberar os horários.'
            : 'As consultas começam sempre em horas inteiras.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: AppSpacing.sm),
      Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          for (final hour in _availableHours)
            Semantics(
              button: true,
              selected: _time?.hour == hour,
              label: 'Horário ${hour.toString().padLeft(2, '0')}:00',
              child: ChoiceChip(
                label: Text('${hour.toString().padLeft(2, '0')}:00'),
                selected: _time?.hour == hour,
                showCheckmark: true,
                onSelected: _isHourInFuture(hour)
                    ? (selected) {
                        if (selected) _selectTime(hour);
                      }
                    : null,
              ),
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      AppTextField(
        label: 'Observações (opcional)',
        hint: 'Conte algo que o profissional precisa saber',
        controller: _notesController,
        maxLines: 4,
        textInputAction: TextInputAction.newline,
        onChanged: (_) => setState(() {}),
      ),
      Align(
        alignment: Alignment.centerRight,
        child: Text('${_notesController.text.length}/1000'),
      ),
      if (_selectedDateTime != null && !_isDateTimeValid)
        const Text('Escolha uma data e um horário futuros.'),
    ],
  );
}
