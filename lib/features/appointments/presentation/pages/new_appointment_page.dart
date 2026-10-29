import 'package:flutter/material.dart';

import '../../../../core/widgets/month_calendar_picker.dart';
import '../../../../core/widgets/time_slot_picker_sheet.dart';
import '../../../../core/utils/input_masks.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_secondary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../../core/widgets/professional_card.dart';
import '../../domain/appointment.dart';
import '../../domain/appointment_failure.dart';
import '../../domain/appointment_repository.dart';
import '../../domain/professional.dart';
import '../../domain/specialty.dart';
import '../widgets/appointment_specialty_picker_sheet.dart';
import 'appointment_created_page.dart';
import 'professional_info_page.dart';

/// Resultado de [NewAppointmentPage] quando o paciente escolhe completar o
/// cadastro antes de agendar. A área do paciente então abre a aba Perfil.
const completeProfileResult = 'completar-perfil';

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
  final _notesController = TextEditingController();
  List<Specialty> _specialties = const [];
  List<Professional> _professionals = const [];
  Specialty? _specialty;
  Professional? _professional;
  DateTime? _day;
  TimeOfDay? _time;
  bool _loading = true;
  List<String> _missingProfileFields = const [];
  bool _loadingProfessionals = false;
  bool _submitting = false;
  int _step = 0;
  String? _error;
  final Map<String, Future<String>> _emailCache = {};

  /// E-mail de contato do fisioterapeuta, buscado uma vez por profissional.
  Future<String> _emailFor(String? professionalId) {
    if (professionalId == null) return Future.value('');
    return _emailCache.putIfAbsent(professionalId, () async {
      final repository = widget.repository;
      final directory = repository is ProfessionalContactDirectory
          ? repository as ProfessionalContactDirectory
          : null;
      if (directory == null) return '';
      try {
        return await directory.fetchProfessionalEmail(professionalId);
      } catch (_) {
        return '';
      }
    });
  }

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

  /// Abre o perfil do profissional. Se o paciente seguir com o agendamento,
  /// o profissional é escolhido e a etapa avança.
  Future<void> _openProfessionalInfo(Professional item) async {
    final follow = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProfessionalInfoPage(
          repository: widget.repository,
          professional: item,
          specialtyName: item.specialtyName.isEmpty
              ? (_specialty?.name ?? '')
              : item.specialtyName,
        ),
      ),
    );
    if (follow != true || !mounted) return;
    setState(() {
      _professional = item;
      _error = null;
    });
    await _continue();
  }

  Future<void> _loadInitialData() async {
    // Paciente sem cadastro completo não agenda: a tela só explica o que falta.
    final repository = widget.repository;
    final checker = repository is PatientProfileChecker
        ? repository as PatientProfileChecker
        : null;
    if (checker != null) {
      try {
        final missing = await checker.missingPatientProfileFields();
        if (!mounted) return;
        if (missing.isNotEmpty) {
          setState(() {
            _missingProfileFields = missing;
            _loading = false;
          });
          return;
        }
      } on AppointmentException catch (error) {
        if (!mounted) return;
        setState(() {
          _error = error.userMessage;
          _loading = false;
        });
        return;
      }
    }
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

  Future<void> _selectTime() async {
    final picked = await TimeSlotPickerSheet.show(
      context,
      initial: _time ?? const TimeOfDay(hour: 9, minute: 0),
      title: 'Escolha o horário',
    );
    if (picked != null && mounted) {
      setState(() {
        _time = picked;
        _error = null;
      });
    }
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
      setState(() => _error = 'Os sintomas devem ter até 1000 caracteres.');
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

  String _crefitoText() {
    final crefito = InputMasks.displayCrefito(_professional?.crefito ?? '');
    return crefito.isEmpty ? '—' : crefito;
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
        : _missingProfileFields.isNotEmpty
        ? EmptyState(
            title: 'Complete seu perfil',
            message:
                'Para agendar, falta preencher: ${_missingProfileFields.join(', ')}.',
            icon: Icons.person_outline,
            actionLabel: 'Completar perfil',
            onAction: () => Navigator.pop(context, completeProfileResult),
          )
        : _error != null && _specialties.isEmpty
        ? ErrorState(message: _error!, onRetry: _loadInitialData)
        : SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
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
                const SizedBox(height: AppSpacing.lg),
                if (_step < 2)
                  AppPrimaryButton(
                    label: _step == 0
                        ? 'Escolher especialidade'
                        : 'Escolher data e horário',
                    onPressed: _canContinue ? _continue : null,
                  )
                else
                  AppPrimaryButton(
                    label: 'Confirmar agendamento',
                    icon: Icons.check,
                    isLoading: _submitting,
                    onPressed: _isDateTimeValid ? _submit : null,
                  ),
              ],
            ),
          ),
  );

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
              onInfo: () => _openProfessionalInfo(item),
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
      Text(
        'Dados do profissional',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: AppSpacing.md),
      InfoLine(
        icon: Icons.person_outline,
        label: 'Fisioterapeuta',
        value: _professional?.name ?? '—',
      ),
      const SizedBox(height: AppSpacing.md),
      InfoLine(
        icon: Icons.medical_services_outlined,
        label: 'Especialização',
        value: _specialty?.name ?? '—',
      ),
      const SizedBox(height: AppSpacing.md),
      InfoLine(
        icon: Icons.badge_outlined,
        label: 'CREFITO',
        value: _crefitoText(),
      ),
      const SizedBox(height: AppSpacing.md),
      FutureBuilder<String>(
        future: _emailFor(_professional?.id),
        builder: (context, snapshot) => InfoLine(
          icon: Icons.email_outlined,
          label: 'E-mail para contato',
          value: (snapshot.data ?? '').isEmpty ? '—' : snapshot.data!,
        ),
      ),
      if ((_professional?.bio ?? '').trim().isNotEmpty) ...[
        const SizedBox(height: AppSpacing.md),
        InfoLine(
          icon: Icons.description_outlined,
          label: 'Descrição',
          value: _professional!.bio,
        ),
      ],
      const SizedBox(height: AppSpacing.lg),
      Text('Selecione o dia', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppSpacing.sm),
      MonthCalendarPicker(
        selected: _day,
        onChanged: (day) => setState(() {
          _day = day;
          _error = null;
        }),
      ),
      const SizedBox(height: AppSpacing.xs),
      AppSecondaryButton(
        onPressed: _selectTime,
        icon: Icons.schedule_outlined,
        label: _time == null ? 'Selecionar horário' : _time!.format(context),
      ),
      const SizedBox(height: AppSpacing.sm),
      AppTextField(
        label: 'Sintomas (opcional)',
        hint: 'Descreva o que você está sentindo',
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
