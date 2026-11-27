import 'package:material_ui/material_ui.dart';
import 'package:medical_domain/medical_domain.dart';

/// Calendar UI adapter. Opening/cancelling the picker does not change a draft.
Future<String?> pickCalendarDate(BuildContext context, String current) async {
  CalendarDate? parsed;
  try {
    parsed = CalendarDate.parse(current);
  } catch (_) {
    /* Incomplete text remains in the form. */
  }
  final now = DateTime.now();
  final selected = await showDatePicker(
    context: context,
    initialDate: parsed == null
        ? now
        : DateTime(parsed.year, parsed.month, parsed.day),
    firstDate: DateTime(1),
    lastDate: DateTime(9999, 12, 31),
  );
  return selected == null
      ? null
      : CalendarDate(selected.year, selected.month, selected.day).toString();
}

Future<String?> pickLocalTime(BuildContext context, String current) async {
  final parts = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(current);
  final valid =
      parts != null && int.parse(parts[1]!) < 24 && int.parse(parts[2]!) < 60;
  final selected = await showTimePicker(
    context: context,
    initialTime: valid
        ? TimeOfDay(hour: int.parse(parts[1]!), minute: int.parse(parts[2]!))
        : TimeOfDay.now(),
  );
  return selected == null
      ? null
      : '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
}
