import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/input_masks.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/dtos/patient_dtos.dart';
import '../../data/viacep_client.dart';
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
    this.cepLookup,
    this.onLogout,
    this.title = 'Editar perfil',
    super.key,
  });

  final PatientProfileFormController controller;
  final Patient currentPatient;
  final VoidCallback onSaved;

  /// Quando informado, aparece o botão de sair na barra superior. Usado no
  /// cadastro obrigatório, em que o paciente ainda não usa o aplicativo.
  final VoidCallback? onLogout;

  final String title;

  /// Consulta de CEP usada para preencher rua/bairro/cidade/estado. Por
  /// padrão usa o [ViaCepClient]; só é injetável para testes.
  final Future<ViaCepAddress> Function(String cep)? cepLookup;

  @override
  State<PatientProfileFormPage> createState() => _PatientProfileFormPageState();
}

enum _CepStatus { idle, loading, notFound, timeout, failed }

class _PatientProfileFormPageState extends State<PatientProfileFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final Future<ViaCepAddress> Function(String cep) _lookupCep =
      widget.cepLookup ?? ViaCepClient().lookup;
  _CepStatus _cepStatus = _CepStatus.idle;

  /// Identifica a consulta de CEP mais recente; respostas de consultas
  /// anteriores (usuário continuou digitando) são descartadas.
  int _cepRequest = 0;

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

  /// CPF e data de nascimento já cadastrados não podem ser alterados: ficam
  /// bloqueados na edição e só são preenchidos no primeiro acesso.
  late final bool _identidadeBloqueada =
      InputMasks.digitsOnly(widget.currentPatient.cpf).length == 11 &&
      widget.currentPatient.dataNascimento != null;

  late DateTime? _dataNascimentoSelecionada =
      widget.currentPatient.dataNascimento;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _cepRequest++;
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

  /// Chamado só quando o usuário edita o CEP (não quando a tela abre
  /// pré-preenchida). Com 8 dígitos consulta o ViaCEP e preenche rua,
  /// bairro, cidade e estado — os campos continuam editáveis, e número e
  /// complemento nunca são tocados. Qualquer falha cai no preenchimento
  /// manual, sem bloquear o formulário.
  Future<void> _onCepChanged(String value) async {
    final digits = InputMasks.digitsOnly(value);
    final request = ++_cepRequest;

    if (digits.length != 8) {
      if (_cepStatus != _CepStatus.idle) {
        setState(() => _cepStatus = _CepStatus.idle);
      }
      return;
    }

    setState(() => _cepStatus = _CepStatus.loading);

    try {
      final address = await _lookupCep(digits);
      if (!mounted || request != _cepRequest) return;
      setState(() {
        _fillIfNotEmpty(_ruaController, address.rua);
        _fillIfNotEmpty(_bairroController, address.bairro);
        _fillIfNotEmpty(_cidadeController, address.cidade);
        _fillIfNotEmpty(_estadoController, address.estado);
        _cepStatus = _CepStatus.idle;
      });
    } on CepLookupException catch (e) {
      if (!mounted || request != _cepRequest) return;
      setState(() {
        _cepStatus = switch (e.failure) {
          CepLookupFailure.notFound => _CepStatus.notFound,
          CepLookupFailure.timeout => _CepStatus.timeout,
          _ => _CepStatus.failed,
        };
      });
    } catch (_) {
      if (!mounted || request != _cepRequest) return;
      setState(() => _cepStatus = _CepStatus.failed);
    }
  }

  // Campos que o ViaCEP não souber (ex.: CEP geral de cidade, sem rua)
  // mantêm o que o usuário já tinha digitado.
  static void _fillIfNotEmpty(TextEditingController controller, String value) {
    if (value.isNotEmpty) controller.text = value;
  }

  Widget _cepFeedback() {
    final message = switch (_cepStatus) {
      _CepStatus.notFound =>
        'CEP não encontrado. Preencha o endereço manualmente.',
      _CepStatus.timeout =>
        'A consulta do CEP demorou demais. Preencha o endereço manualmente.',
      _CepStatus.failed =>
        'Não foi possível consultar o CEP. Preencha o endereço manualmente.',
      _CepStatus.idle || _CepStatus.loading => null,
    };
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4),
      child: Text(
        message,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  /// Lê a data digitada (DD/MM/AAAA). Vazia ou incompleta vira null.
  void _onDataNascimentoChanged(String value) {
    setState(() => _dataNascimentoSelecionada = InputMasks.parseDate(value));
  }

  String? _validateDataNascimento(String? value) {
    final date = InputMasks.parseDate(value ?? '');
    if (date == null) return 'Informe uma data válida.';
    return null;
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
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (widget.onLogout != null)
            IconButton(
              tooltip: 'Sair',
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
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
                  enabled: !_identidadeBloqueada,
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
                  enabled: !_identidadeBloqueada,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [InputMasks.dataFormatter()],
                  onChanged: _onDataNascimentoChanged,
                  hint: 'DD/MM/AAAA',
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: _validateDataNascimento,
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
                  onChanged: _onCepChanged,
                  suffixIcon: _cepStatus == _CepStatus.loading
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
                _cepFeedback(),
                _fieldError(controller, 'cep'),
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
    // O backend pode guardar um valor que não bate exatamente com nenhuma
    // das opções fixas (acentuação/maiúscula diferente, ou valor antigo).
    // O DropdownButtonFormField lança assertion se o initialValue não
    // estiver em `items` — então, em vez de travar a tela ou descartar o
    // dado, o valor real entra como uma opção extra no topo da lista.
    final resolvedOptions = (value.isNotEmpty && !options.contains(value))
        ? [value, ...options]
        : options;

    return DropdownButtonFormField<String>(
      initialValue: value.isEmpty ? null : value,
      decoration: InputDecoration(labelText: label),
      items: resolvedOptions
          .map((option) => DropdownMenuItem(value: option, child: Text(option)))
          .toList(),
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }
}
