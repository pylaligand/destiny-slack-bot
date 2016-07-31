// Copyright (c) 2016 P.Y. Laligand

import 'package:timezone/standalone.dart';

const _DAYS_OF_WEEK = const [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday'
];

/// Generates a representation of the given date that depends on the proximity
/// to the present time.
String formatDay(TZDateTime date, TZDateTime now) {
  final deltaDays = date.difference(now).abs().inDays;
  if (deltaDays == 0 && date.day == now.day) {
    return 'Today';
  } else if (0 <= deltaDays &&
      deltaDays <= 1 &&
      date.day != now.add(const Duration(days: 2)).day) {
    return 'Tomorrow';
  } else if (deltaDays < 7 &&
      date.day != now.add(const Duration(days: 7)).day) {
    return _DAYS_OF_WEEK[date.weekday - 1];
  } else {
    return '${date.month}/${date.day}';
  }
}
