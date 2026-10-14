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
/// IMPORTANTE: não tenho o PacienteUpdateDTO.cs real do backend — esses
/// nomes de campo seguem o padrão do ProfissionalUpdateDTO (mesma equipe,
/// mesmo estilo de PUT completar-perfil) e os campos da entidade Paciente.cs
/// que vocês me mandaram. Se o DTO real do Jonas/João V. usar nomes
/// diferentes, só este arquivo (o toJson) precisa mudar — nada mais na tela
/// depende do formato exato da API.
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
    'endereco': {
      'rua': endereco.rua,
      'numero': endereco.numero,
      'complemento': endereco.complemento,
      'cep': endereco.cep,
      'bairro': endereco.bairro,
      'cidade': endereco.cidade,
      'estado': endereco.estado,
    },
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