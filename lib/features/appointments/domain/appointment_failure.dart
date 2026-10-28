enum AppointmentFailure {
  network,
  unauthorized,
  notFound,
  conflict,
  invalid,
  incompleteProfile,
  unexpected,
}

class AppointmentException implements Exception {
  const AppointmentException(this.failure, {this.message});

  final AppointmentFailure failure;
  final String? message;

  String get userMessage =>
      message ??
      switch (failure) {
        AppointmentFailure.network => 'Confira sua conexão e tente novamente.',
        AppointmentFailure.unauthorized =>
          'Sua sessão expirou. Entre novamente.',
        AppointmentFailure.notFound =>
          'O item solicitado não foi encontrado ou está indisponível.',
        AppointmentFailure.conflict =>
          'Esse horário acabou de ser reservado. Escolha outro horário.',
        AppointmentFailure.invalid =>
          'Confira os dados do agendamento e tente novamente.',
        AppointmentFailure.incompleteProfile => 'Complete seu cadastro (nome, CPF, data de nascimento, telefone e endereço) antes de agendar.',
        AppointmentFailure.unexpected =>
          'Não foi possível concluir a solicitação. Tente novamente.',
      };
}
