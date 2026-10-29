/// Entidade de domínio do paciente — sem nenhuma dependência de widgets ou
/// de formato de API, só os dados que a tela precisa exibir e editar.
class PatientAddress {
  const PatientAddress({
    this.rua = '',
    this.numero = '',
    this.complemento = '',
    this.cep = '',
    this.bairro = '',
    this.cidade = '',
    this.estado = '',
  });

  final String rua;
  final String numero;
  final String complemento;
  final String cep;
  final String bairro;
  final String cidade;
  final String estado;

  bool get isEmpty =>
      rua.isEmpty &&
      numero.isEmpty &&
      complemento.isEmpty &&
      cep.isEmpty &&
      bairro.isEmpty &&
      cidade.isEmpty &&
      estado.isEmpty;
}

class Patient {
  const Patient({
    required this.nomeCompleto,
    required this.cpf,
    required this.telefone,
    required this.dataNascimento,
    required this.sexo,
    required this.estadoCivil,
    required this.endereco,
    required this.email,
  });

  final String nomeCompleto;
  final String cpf;
  final String telefone;
  final DateTime? dataNascimento;
  final String sexo;
  final String estadoCivil;
  final PatientAddress endereco;
  final String email;

  /// Verdadeiro para o perfil ainda não preenchido pelo cadastro
  /// ("Cadastro Pendente"), que é como o AuthService cria o paciente no
  /// registro — ajuda a decidir se mostra "Completar perfil" em vez de
  /// "Editar perfil".
  bool get isPendingCompletion => nomeCompleto.trim() == 'Cadastro Pendente';

  /// Cadastro com todos os dados obrigatórios para usar o aplicativo.
  bool get isComplete {
    final birth = dataNascimento;
    return !isPendingCompletion &&
        nomeCompleto.trim().isNotEmpty &&
        cpf.replaceAll(RegExp(r'\D'), '').length == 11 &&
        birth != null &&
        birth.year > 1900 &&
        telefone.trim().isNotEmpty &&
        endereco.rua.trim().isNotEmpty &&
        endereco.numero.trim().isNotEmpty &&
        endereco.cep.trim().isNotEmpty &&
        endereco.bairro.trim().isNotEmpty &&
        endereco.cidade.trim().isNotEmpty &&
        endereco.estado.trim().isNotEmpty;
  }
}
