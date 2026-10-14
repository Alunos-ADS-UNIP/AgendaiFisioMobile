import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/input_masks.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/dtos/patient_dtos.dart';
import '../../domain/patient.dart';
import '../controllers/patient_profile_form_controller.dart';

/// Formulário de completar/editar o perfil do paciente.
/// PUT /api/paciente/completar-perfil.
///
/// Campos opcionais que o paciente deixar em branco aqui não devem apagar
/// valores já salvos — por isso a tela sempre abre pré-preenchida com o
/// [currentPatient] vindo do GET /me, em vez de abrir vazia.
class PatientProfileFormPage extends StatefulWidget {
  const PatientProfileFormPage({
    required this.controller,
    required this.currentPatient,
    required this.onSaved,
    super.key,
  });

  final PatientProfileFormController controller;
  final Patient currentPatient;
  final VoidCallback onSaved;

  @override
  State<PatientProfileFormPage> createState() => _PatientProfileFormPageState();
}

class _PatientProfileFormPageState extends State<PatientProfileFormPage> {
  final _formKey = GlobalKey<FormState>();

  // "Cadastro Pendente" é só o placeholder que o backend usa pra nome ainda
  // não preenchido (ver Patient.isPendingCompletion) — não deve aparecer
  // pré-preenchido no formulário como se fosse um nome de verdade.
  late final _nomeController = TextEditingController(
    text: widget.currentPatient.isPendingCompletion
        ? ''
        : widget.currentPatient.nomeCompleto,
  );
  late final _cpfController = TextEditingController(
    text: InputMasks.applyMask(InputMasks.cpf, widget.currentPatient.cpf),
  );
  late final _telefoneController = TextEditingController(
    text: InputMasks.applyMask(
      InputMasks.telefone,
      widget.currentPatient.telefone,
    ),
  );
  late final _dataNascimentoController = TextEditingController(
    text: widget.currentPatient.dataNascimento == null
        ? ''
        : _formatDate(widget.currentPatient.dataNascimento!),
  );
  late String _sexo = widget.currentPatient.sexo.isEmpty
      ? ''
      : widget.currentPatient.sexo;
  late String _estadoCivil = widget.currentPatient.estadoCivil.isEmpty
      ? ''
      : widget.currentPatient.estadoCivil;

  late final _ruaController = TextEditingController(
    text: widget.currentPatient.endereco.rua,
  );
  late final _numeroController = TextEditingController(
    text: widget.currentPatient.endereco.numero,
  );
  late final _complementoController = TextEditingController(
    text: widget.currentPatient.endereco.complemento,
  );
  late final _cepController = TextEditingController(
    text: InputMasks.applyMask(
      InputMasks.cep,
      widget.currentPatient.endereco.cep,
    ),
  );
  late final _bairroController = TextEditingController(
    text: widget.currentPatient.endereco.bairro,
  );
  late final _cidadeController = TextEditingController(
    text: widget.currentPatient.endereco.cidade,
  );
  late final _estadoController = TextEditingController(
    text: widget.currentPatient.endereco.estado,
  );

  late DateTime? _dataNascimentoSelecionada =
      widget.currentPatient.dataNascimento;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _nomeController.dispose();
    _cpfController.dispose();
    _telefoneController.dispose();
    _dataNascimentoController.dispose();
    _ruaController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    _cepController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  Future<void> _pickDataNascimento() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataNascimentoSelecionada ?? DateTime(now.year - 30),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Data de nascimento',
    );
    if (picked != null) {
      setState(() {
        _dataNascimentoSelecionada = picked;
        _dataNascimentoController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_dataNascimentoSelecionada == null) {
      setState(() {}); // força reexibir o validator da data
      return;
    }

    final request = PatientUpdateRequest(
      nomeCompleto: _nomeController.text.trim(),
      cpf: InputMasks.digitsOnly(_cpfController.text),
      telefone: InputMasks.digitsOnly(_telefoneController.text),
      dataNascimento: _dataNascimentoSelecionada!,
      sexo: _sexo,
      estadoCivil: _estadoCivil,
      endereco: PatientAddress(
        rua: _ruaController.text.trim(),
        numero: _numeroController.text.trim(),
        complemento: _complementoController.text.trim(),
        cep: InputMasks.digitsOnly(_cepController.text),
        bairro: _bairroController.text.trim(),
        cidade: _cidadeController.text.trim(),
        estado: _estadoController.text.trim(),
      ),
    );

    final success = await widget.controller.submit(request);
    if (success && mounted) {
      widget.onSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Dados pessoais',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Nome completo',
                  controller: _nomeController,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Informe seu nome completo.'
                      : null,
                ),
                _fieldError(controller, 'nomeCompleto'),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'CPF',
                  controller: _cpfController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [InputMasks.cpfFormatter()],
                  validator: (v) {
                    final digits = InputMasks.digitsOnly(v ?? '');
                    if (digits.length != 11) return 'CPF deve ter 11 dígitos.';
                    return null;
                  },
                ),
                _fieldError(controller, 'cpf'),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Telefone',
                  controller: _telefoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [InputMasks.telefoneFormatter()],
                  validator: (v) {
                    final digits = InputMasks.digitsOnly(v ?? '');
                    if (digits.length < 10 || digits.length > 11) {
                      return 'Telefone deve ter 10 ou 11 dígitos, com DDD.';
                    }
                    return null;
                  },
                ),
                _fieldError(controller, 'telefone'),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Data de nascimento',
                  controller: _dataNascimentoController,
                  readOnly: true,
                  onTap: _pickDataNascimento,
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                  validator: (_) => _dataNascimentoSelecionada == null
                      ? 'Selecione a data de nascimento.'
                      : null,
                ),
                _fieldError(controller, 'dataNascimento'),
                const SizedBox(height: AppSpacing.md),
                _ChoiceField(
                  label: 'Sexo',
                  value: _sexo,
                  options: const ['Feminino', 'Masculino', 'Outro'],
                  onChanged: (value) => setState(() => _sexo = value),
                ),
                const SizedBox(height: AppSpacing.md),
                _ChoiceField(
                  label: 'Estado civil',
                  value: _estadoCivil,
                  options: const [
                    'Solteiro(a)',
                    'Casado(a)',
                    'Divorciado(a)',
                    'Viúvo(a)',
                  ],
                  onChanged: (value) => setState(() => _estadoCivil = value),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Endereço', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'CEP',
                  controller: _cepController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [InputMasks.cepFormatter()],
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(label: 'Rua', controller: _ruaController),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Número',
                        controller: _numeroController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: AppTextField(
                        label: 'Complemento',
                        controller: _complementoController,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(label: 'Bairro', controller: _bairroController),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: AppTextField(
                        label: 'Cidade',
                        controller: _cidadeController,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppTextField(
                        label: 'Estado',
                        controller: _estadoController,
                      ),
                    ),
                  ],
                ),
                if (controller.generalError != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    controller.generalError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppPrimaryButton(
                  label: 'Salvar',
                  isLoading: controller.isSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldError(PatientProfileFormController controller, String field) {
    final message = controller.errorFor(field);
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4),
      child: Text(
        message,
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ChoiceField extends StatelessWidget {
  const _ChoiceField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value.isEmpty ? null : value,
      decoration: InputDecoration(labelText: label),
      items: options
          .map((option) => DropdownMenuItem(value: option, child: Text(option)))
          .toList(),
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }
}
