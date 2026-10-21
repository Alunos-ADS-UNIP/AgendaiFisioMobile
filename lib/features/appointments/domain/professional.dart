class Professional {
  const Professional({
    required this.id,
    required this.name,
    required this.specialtyId,
    required this.specialtyName,
    this.crefito = '',
    this.bio = '',
    this.isActive = true,
  });

  final String id;
  final String name;
  final String? specialtyId;
  final String specialtyName;
  final String crefito;
  final String bio;
  final bool isActive;
}
