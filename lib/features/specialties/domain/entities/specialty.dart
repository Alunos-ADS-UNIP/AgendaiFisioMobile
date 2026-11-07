class Specialty {
  const Specialty({required this.id, required this.name});

  final String id;
  final String name;

  @override
  bool operator ==(Object other) => other is Specialty && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
