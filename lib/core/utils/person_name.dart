/// Placeholder que o backend usa enquanto o perfil não foi preenchido.
const _pendingProfileName = 'Cadastro Pendente';

/// Primeiro nome de [fullName], com a primeira letra maiúscula, para
/// saudações ("Olá, Maria!"). Devolve string vazia quando não há nome de
/// verdade (vazio ou o placeholder "Cadastro Pendente"), para a tela cair
/// em "Olá!" em vez de mostrar lixo.
String firstName(String? fullName) {
  final trimmed = (fullName ?? '').trim();
  if (trimmed.isEmpty || trimmed == _pendingProfileName) return '';
  final first = trimmed.split(RegExp(r'\s+')).first;
  return first.substring(0, 1).toUpperCase() + first.substring(1);
}
