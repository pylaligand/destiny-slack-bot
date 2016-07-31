// Copyright (c) 2016 P.Y. Laligand

import 'package:test/test.dart';
import 'package:timezone/standalone.dart';

import '../../lib/utils/dates.dart';

main() async {
  await initializeTimeZone();

  group('formatDay', () {
    test('today', () {
      final now = new TZDateTime.utc(2016, 7, 13, 17, 35);
      final later = new TZDateTime.utc(2016, 7, 13, 21, 45);
      expect(formatDay(later, now), equals('Today'));
    });

    test('not today', () {
      final now = new TZDateTime.utc(2016, 7, 13, 17, 35);
      final later = new TZDateTime.utc(2016, 7, 14, 1, 00);
      expect(formatDay(later, now), isNot(equals('Today')));
    });

    test('tomorrow', () {
      final now = new TZDateTime.utc(2016, 7, 13, 17, 35);
      final later = new TZDateTime.utc(2016, 7, 14, 1, 00);
      expect(formatDay(later, now), equals('Tomorrow'));
    });

    test('tomorrow across month', () {
      final now = new TZDateTime.utc(2016, 7, 31, 17, 35);
      final later = new TZDateTime.utc(2016, 8, 1, 1, 00);
      expect(formatDay(later, now), equals('Tomorrow'));
    });

    test('not tomorrow', () {
      final now = new TZDateTime.utc(2016, 7, 13, 17, 35);
      final later = new TZDateTime.utc(2016, 7, 15, 1, 00);
      expect(formatDay(later, now), isNot(equals('Tomorrow')));
    });

    test('this week', () {
      final now = new TZDateTime.utc(2016, 7, 13, 17, 35);
      final later = new TZDateTime.utc(2016, 7, 19, 21, 00);
      expect(formatDay(later, now), isNot(contains('/')));
    });

    test('not this week', () {
      final now = new TZDateTime.utc(2016, 7, 13, 17, 35);
      final later = new TZDateTime.utc(2016, 7, 20, 1, 00);
      expect(formatDay(later, now), contains('/'));
    });
  });
}
