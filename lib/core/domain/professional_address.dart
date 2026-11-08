class ProfessionalAddress {
  const ProfessionalAddress({
    required this.street,
    required this.number,
    required this.complement,
    required this.zipCode,
    required this.neighborhood,
    required this.city,
    required this.state,
  });

  final String street;
  final String number;
  final String complement;
  final String zipCode;
  final String neighborhood;
  final String city;
  final String state;

  bool get isComplete =>
      street.trim().isNotEmpty &&
      number.trim().isNotEmpty &&
      zipCode.replaceAll(RegExp(r'\D'), '').length == 8 &&
      neighborhood.trim().isNotEmpty &&
      city.trim().isNotEmpty &&
      state.trim().length == 2;

  String get line {
    final first = [
      street,
      number,
    ].where((value) => value.trim().isNotEmpty).join(', ');
    return [
      first,
      complement,
      neighborhood,
      [city, state].where((value) => value.trim().isNotEmpty).join(' - '),
    ].where((value) => value.trim().isNotEmpty).join(' • ');
  }
}
