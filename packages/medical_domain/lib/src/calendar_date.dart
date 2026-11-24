/// A complete Gregorian date without a time or time zone.
///
/// Partial dates and approximate periods require separate domain types.
final class CalendarDate implements Comparable<CalendarDate> {
  factory CalendarDate(int year, int month, int day) {
    if (year < 1 || year > 9999 || month < 1 || month > 12) {
      throw ArgumentError('Invalid calendar date');
    }
    final leap = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
    final days = <int>[
      31,
      leap ? 29 : 28,
      31,
      30,
      31,
      30,
      31,
      31,
      30,
      31,
      30,
      31,
    ];
    if (day < 1 || day > days[month - 1]) {
      throw ArgumentError('Invalid calendar date');
    }
    return CalendarDate._(year, month, day);
  }

  const CalendarDate._(this.year, this.month, this.day);

  /// Parses exactly YYYY-MM-DD without normalizing invalid dates.
  factory CalendarDate.parse(String value) {
    if (value.length != 10 || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      throw const FormatException('Expected YYYY-MM-DD');
    }
    try {
      return CalendarDate(
        int.parse(value.substring(0, 4)),
        int.parse(value.substring(5, 7)),
        int.parse(value.substring(8, 10)),
      );
    } on ArgumentError {
      throw const FormatException('Invalid calendar date');
    }
  }

  final int year;
  final int month;
  final int day;

  @override
  int compareTo(CalendarDate other) {
    final years = year.compareTo(other.year);
    if (years != 0) return years;
    final months = month.compareTo(other.month);
    return months != 0 ? months : day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is CalendarDate &&
      year == other.year &&
      month == other.month &&
      day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}
