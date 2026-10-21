import '../../domain/patient.dart';

/// Quando o paciente ainda não preencheu a data de nascimento, o backend
/// manda o valor "vazio" padrão do DateTime do C# ("0001-01-01T00:00:00")
/// em vez de null. Tratamos isso como "sem data" — igual os outros campos
/// (cpf, telefone etc.) vêm como string vazia nesse caso.
DateTime? _parseDataNascimento(dynamic value) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  if (parsed == null || parsed.year <= 1) return null;
  return parsed;
}

/// Corpo do POST /api/auth/register para criar uma conta de Paciente.
/// Segue exatamente o UsuarioRegisterDTO do backend (email, senha,
/// tipoUsuario).
class PatientRegisterRequest {
  const PatientRegisterRequest({required this.email, required this.senha});

  final String email;
  final String senha;

  Map<String, dynamic> toJson() => {
    'email': email,
    'senha': senha,
    'tipoUsuario': 'Paciente',
  };
}

/// Corpo do PUT /api/paciente/completar-perfil.
///
/// CONTRATO (PacienteUpdateDTO do backend): os campos de endereço (`rua`,
/// `numero`, `complemento`, `cep`, `bairro`, `cidade`, `estado`) vão
/// **direto na raiz** do JSON, junto com os dados pessoais. Já o GET
/// /api/paciente/me devolve o endereço aninhado em `endereco` (ver
/// [PatientProfileResponse]) — a assimetria é do backend.
///
/// Atenção: se o endereço for aninhado no PUT, o backend responde 200 mas
/// ignora o endereço inteiro (o GET seguinte volta vazio). O teste de
/// contrato em test/features/patients/patient_contract_test.dart protege
/// contra essa regressão.
class PatientUpdateRequest {
  const PatientUpdateRequest({
    required this.nomeCompleto,
    required this.cpf,
    required this.telefone,
    required this.dataNascimento,
    required this.sexo,
    required this.estadoCivil,
    required this.endereco,
  });

  final String nomeCompleto;
  final String cpf;
  final String telefone;
  final DateTime dataNascimento;
  final String sexo;
  final String estadoCivil;
  final PatientAddress endereco;

  Map<String, dynamic> toJson() => {
    'nomeCompleto': nomeCompleto,
    'cpf': cpf,
    'telefone': telefone,
    // ISO 8601 (yyyy-MM-dd), formato que o System.DateTime do backend aceita.
    'dataNascimento': dataNascimento.toIso8601String().split('T').first,
    'sexo': sexo,
    'estadoCivil': estadoCivil,
    // Endereço achatado na raiz, como o PacienteUpdateDTO espera.
    'rua': endereco.rua,
    'numero': endereco.numero,
    'complemento': endereco.complemento,
    'cep': endereco.cep,
    'bairro': endereco.bairro,
    'cidade': endereco.cidade,
    'estado': endereco.estado,
  };
}

/// Resposta do GET /api/paciente/me.
///
/// Confirmado via Scalar em 13/10 — os nomes de campo batem com o que foi
/// previsto aqui (nomeCompleto, cpf, telefone, dataNascimento, sexo,
/// estadoCivil, endereco{...}, email). Perfil ainda não preenchido vem com
/// nomeCompleto "Cadastro Pendente" e os demais campos como string vazia.
class PatientProfileResponse {
  const PatientProfileResponse({
    required this.nomeCompleto,
    required this.cpf,
    required this.telefone,
    required this.dataNascimento,
    required this.sexo,
    required this.estadoCivil,
    required this.endereco,
    required this.email,
  });

  factory PatientProfileResponse.fromJson(Map<String, dynamic> json) {
    final enderecoJson = json['endereco'] as Map<String, dynamic>?;

    return PatientProfileResponse(
      nomeCompleto: json['nomeCompleto']?.toString() ?? '',
      cpf: json['cpf']?.toString() ?? '',
      telefone: json['telefone']?.toString() ?? '',
      dataNascimento: _parseDataNascimento(json['dataNascimento']),
      sexo: json['sexo']?.toString() ?? '',
      estadoCivil: json['estadoCivil']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      endereco: PatientAddress(
        rua: enderecoJson?['rua']?.toString() ?? '',
        numero: enderecoJson?['numero']?.toString() ?? '',
        complemento: enderecoJson?['complemento']?.toString() ?? '',
        cep: enderecoJson?['cep']?.toString() ?? '',
        bairro: enderecoJson?['bairro']?.toString() ?? '',
        cidade: enderecoJson?['cidade']?.toString() ?? '',
        estado: enderecoJson?['estado']?.toString() ?? '',
      ),
    );
  }

  final String nomeCompleto;
  final String cpf;
  final String telefone;
  final DateTime? dataNascimento;
  final String sexo;
  final String estadoCivil;
  final PatientAddress endereco;
  final String email;

  Patient toDomain() => Patient(
    nomeCompleto: nomeCompleto,
    cpf: cpf,
    telefone: telefone,
    dataNascimento: dataNascimento,
    sexo: sexo,
    estadoCivil: estadoCivil,
    endereco: endereco,
    email: email,
  );
}
