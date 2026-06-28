import 'package:doctor_app/features/dashboard/utils/schedule_date_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveScheduleDate', () {
    final now = DateTime(2026, 6, 26, 10, 30);

    test('uses tour start date while a tour is active', () {
      final result = resolveScheduleDate(
        hasActiveTour: true,
        tourStartDate: '2026-06-25',
        requestedDate: now,
        now: now,
      );

      expect(result, DateTime(2026, 6, 25));
    });

    test('keeps restored tour start date after an app restart', () {
      final result = resolveScheduleDate(
        hasActiveTour: true,
        tourStartDate: '2026-06-25',
        now: now,
      );

      expect(result, DateTime(2026, 6, 25));
    });

    test('uses current date after the active tour has ended', () {
      final result = resolveScheduleDate(
        hasActiveTour: false,
        tourStartDate: '',
        now: now,
      );

      expect(result, now);
    });

    test('uses requested date when there is no active tour', () {
      final requestedDate = DateTime(2026, 6, 24);

      final result = resolveScheduleDate(
        hasActiveTour: false,
        tourStartDate: '',
        requestedDate: requestedDate,
        now: now,
      );

      expect(result, requestedDate);
    });

    test('falls back safely when active tour start date is invalid', () {
      final result = resolveScheduleDate(
        hasActiveTour: true,
        tourStartDate: 'invalid-date',
        now: now,
      );

      expect(result, now);
    });
  });
}
