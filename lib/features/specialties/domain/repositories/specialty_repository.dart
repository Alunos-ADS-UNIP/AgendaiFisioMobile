import '../entities/specialty.dart';

abstract interface class SpecialtyRepository {
  Future<List<Specialty>> list();

  Future<Specialty> getById(String id);

  Future<void> updateProfessionalSpecialty(String specialtyId);
}
