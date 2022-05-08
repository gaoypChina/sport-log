import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const _shortMonthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String shortMonthName(int month) {
  return _shortMonthNames[month - 1];
}

const _shortWeekdayNames = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

String shortWeekdayName(int weekday) {
  return _shortWeekdayNames[weekday - 1];
}

extension FormatDuration on Duration {
  String get formatTime => toString().split('.').first.padLeft(8, "0");

  String get formatTimeShort => inSeconds < 3600
      ? toString().split('.').first.split(":").skip(1).join(":")
      : toString().split('.').first.padLeft(8, "0");

  String get formatTimeWithMillis => toString().split(":").skip(1).join(":");
}

extension TimeOfDayExtension on TimeOfDay {
  DateTime toDateTime() {
    final now = DateTime.now();

    return DateTime(now.year, now.month, now.day, hour, minute);
  }
}

extension DateTimeExtension on DateTime {
  String get shortMonthName => _shortMonthNames[month - 1];
  String get shortWeekdayName => _shortWeekdayNames[weekday - 1];

  String get _formatDate => DateFormat("dd'.' MMMM yyyy").format(this);
  String get _formatDateShort => DateFormat("dd'.' MMMM").format(this);
  String get formatDateyyyyMMdd => DateFormat('yyyy-MM-dd').format(this);

  String get _formatMonth => DateFormat('MMMM yyyy').format(this);
  String get _formatMonthShort => DateFormat.MMMM().format(this);

  String get _formatWeekday => DateFormat.EEEE().format(this);

  String get formatTimeHms => DateFormat.Hms().format(this);
  String get formatTime => DateFormat.Hm().format(this);

  String toHumanDateTime() => '${toHumanDay()} at $formatTime';

  String toHumanDate() => toHumanDay();

  String toHumanDay() {
    final now = DateTime.now();
    if (isOnDay(now)) {
      return 'Today';
    } else if (isOnDay(DateTime.now().dayEarlier())) {
      return 'Yesterday';
    } else if (isOnDay(DateTime.now().dayLater())) {
      return 'Tomorrow';
    } else if (isInWeek(now)) {
      return _formatWeekday;
    } else if (isInYear(now)) {
      return _formatDateShort;
    } else {
      return _formatDate;
    }
  }

  String toHumanWeek() {
    final now = DateTime.now();
    if (isInWeek(now)) {
      return 'This week';
    } else if (weekLater().isInWeek(now)) {
      return 'Last week';
    } else if (isInYear(now)) {
      final lastDay = add(const Duration(days: 6));
      return "$_formatDateShort - ${lastDay._formatDateShort}";
    } else {
      final lastDay = add(const Duration(days: 6));
      return "$_formatDate - ${lastDay._formatDate}";
    }
  }

  String toHumanMonth() {
    final now = DateTime.now();
    if (isInMonth(now)) {
      return 'This month';
    } else if (monthLater().isInMonth(now)) {
      return 'Last month';
    } else if (isInYear(now)) {
      return _formatMonthShort;
    } else {
      return _formatMonth;
    }
  }

  String toHumanYear() {
    final now = DateTime.now();
    if (isInYear(now)) {
      return 'This year';
    } else if (yearLater().isInYear(now)) {
      return 'Last year';
    } else {
      return year.toString();
    }
  }

  DateTime beginningOfDay() {
    return DateTime(year, month, day);
  }

  DateTime beginningOfWeek() {
    final difference = weekday - DateTime.monday;
    return DateTime(year, month, day).subtract(Duration(days: difference));
  }

  DateTime beginningOfMonth() {
    return DateTime(year, month);
  }

  DateTime beginningOfYear() {
    return DateTime(year);
  }

  DateTime endOfDay() {
    return DateTime(year, month, day + 1);
  }

  DateTime endOfWeek() {
    return beginningOfWeek().weekLater();
  }

  DateTime endOfMonth() {
    return DateTime(year, month + 1, 1);
  }

  DateTime endOfYear() {
    return DateTime(year + 1);
  }

  DateTime dayLater() {
    return DateTime(year, month, day + 1);
  }

  DateTime weekLater() {
    return DateTime(year, month, day + 7);
  }

  DateTime monthLater() {
    return DateTime(year, month + 1, day);
  }

  DateTime yearLater() {
    return DateTime(year + 1, month, day);
  }

  DateTime dayEarlier() {
    return DateTime(year, month, day - 1);
  }

  DateTime weekEarlier() {
    return DateTime(year, month, day - 7);
  }

  DateTime monthEarlier() {
    return DateTime(year, month - 1, day);
  }

  DateTime yearEarlier() {
    return DateTime(year - 1, month, day);
  }

  // start inclusive, end exclusive
  bool isBetween(DateTime start, DateTime end) {
    return isAtSameMomentAs(start) || (isAfter(start) && isBefore(end));
  }

  bool isOnDay(DateTime date) {
    return day == date.day && month == date.month && year == date.year;
  }

  bool isInWeek(DateTime date) {
    final _date = date.beginningOfWeek();
    return isBetween(_date, _date.weekLater());
  }

  bool isInMonth(DateTime date) {
    return month == date.month && year == date.year;
  }

  bool isInYear(DateTime date) {
    return year == date.year;
  }

  bool get isLeapYear {
    return (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
  }

  int get numDaysInMonth {
    const numDaysNormYear = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    const numDaysLeapYear = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return isLeapYear ? numDaysLeapYear[month - 1] : numDaysNormYear[month - 1];
  }

  int get numDaysInYear => isLeapYear ? 366 : 365;

  DateTime withTime(TimeOfDay time) {
    return DateTime(year, month, day, time.hour, time.minute);
  }

  // ignore: long-parameter-list
  DateTime copyWith({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? millisecond,
    int? microsecond,
  }) {
    return DateTime(
      year ?? this.year,
      month ?? this.month,
      day ?? this.day,
      hour ?? this.hour,
      minute ?? this.minute,
      second ?? this.second,
      millisecond ?? this.millisecond,
      microsecond ?? this.microsecond,
    );
  }
}
