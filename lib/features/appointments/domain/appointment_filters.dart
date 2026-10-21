import '../../../core/models/appointment_status.dart';
import 'appointment.dart';

class AppointmentFilters {
  const AppointmentFilters({this.day, this.professionalId, this.status});

  final DateTime? day;
  final String? professionalId;
  final AppointmentStatus? status;

  bool get isEmpty => day == null && professionalId == null && status == null;

  List<Appointment> apply(List<Appointment> appointments) => appointments
      .where((item) {
        if (day != null &&
            (item.dateTime.year != day!.year ||
                item.dateTime.month != day!.month ||
                item.dateTime.day != day!.day)) {
          return false;
        }
        if (professionalId != null && item.professionalId != professionalId) {
          return false;
        }
        if (status != null && item.status != status) return false;
        return true;
      })
      .toList(growable: false);
}
