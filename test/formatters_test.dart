import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:grh_mobile/core/utils/formatters.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_TG', null);
  });

  group('AppFormatters', () {
    group('currency', () {
      test('formats currency correctly', () {
        final result = AppFormatters.currency(1500000);
        expect(result, contains('1'));
        expect(result, contains('500'));
      });

      test('formats zero', () {
        final result = AppFormatters.currency(0);
        expect(result, contains('0'));
      });

      test('formats null as zero', () {
        final result = AppFormatters.currency(null);
        expect(result, contains('0'));
      });
    });

    group('shortDate', () {
      test('formats date correctly', () {
        final date = DateTime(2026, 5, 2);
        final result = AppFormatters.shortDate(date);
        expect(result, contains('02'));
        expect(result, contains('05'));
        expect(result, contains('2026'));
      });

      test('returns N/A for null', () {
        final result = AppFormatters.shortDate(null);
        expect(result, 'N/A');
      });
    });

    group('percentage', () {
      test('formats percentage correctly', () {
        final result = AppFormatters.percentage(75.5);
        expect(result, contains('75'));
      });

      test('handles zero', () {
        final result = AppFormatters.percentage(0);
        expect(result, contains('0'));
      });

      test('handles null', () {
        final result = AppFormatters.percentage(null);
        expect(result, contains('0'));
      });
    });
  });
}
