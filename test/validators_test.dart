import 'package:flutter_test/flutter_test.dart';
import 'package:grh_mobile/core/utils/validators.dart';

void main() {
  group('FormValidators', () {
    group('validateEmail', () {
      test('returns null for valid email', () {
        expect(
          FormValidators.validateEmail('user@example.com'),
          isNull,
        );
      });

      test('returns error for invalid email', () {
        expect(
          FormValidators.validateEmail('invalid-email'),
          isNotNull,
        );
      });

      test('returns error for empty email', () {
        expect(
          FormValidators.validateEmail(''),
          isNotNull,
        );
      });
    });

    group('validatePassword', () {
      test('returns null for valid password', () {
        expect(
          FormValidators.validatePassword('Password123'),
          isNull,
        );
      });

      test('returns error for password < 6 chars', () {
        expect(
          FormValidators.validatePassword('Pass1'),
          isNotNull,
        );
      });

      test('returns error for password without uppercase', () {
        expect(
          FormValidators.validatePassword('password123'),
          isNotNull,
        );
      });

      test('returns error for password without lowercase', () {
        expect(
          FormValidators.validatePassword('PASSWORD123'),
          isNotNull,
        );
      });

      test('returns error for password without number', () {
        expect(
          FormValidators.validatePassword('PasswordABC'),
          isNotNull,
        );
      });
    });

    group('validateRequired', () {
      test('returns null for non-empty value', () {
        expect(
          FormValidators.validateRequired('some value'),
          isNull,
        );
      });

      test('returns error for empty value', () {
        expect(
          FormValidators.validateRequired(''),
          isNotNull,
        );
      });
    });

    group('validatePhoneTG', () {
      test('returns null for valid TG phone', () {
        expect(
          FormValidators.validatePhoneTG('22892123456'),
          isNull,
        );
      });

      test('returns error for invalid phone', () {
        expect(
          FormValidators.validatePhoneTG('123456'),
          isNotNull,
        );
      });
    });

    group('validateAmount', () {
      test('returns null for valid amount', () {
        expect(
          FormValidators.validateAmount('1500.50'),
          isNull,
        );
      });

      test('returns error for negative amount', () {
        expect(
          FormValidators.validateAmount('-100'),
          isNotNull,
        );
      });

      test('returns error for zero amount', () {
        expect(
          FormValidators.validateAmount('0'),
          isNotNull,
        );
      });

      test('returns error for invalid amount', () {
        expect(
          FormValidators.validateAmount('abc'),
          isNotNull,
        );
      });
    });

    group('validateLeaveDays', () {
      test('returns null for valid days', () {
        expect(
          FormValidators.validateLeaveDays('5', 10),
          isNull,
        );
      });

      test('returns error for more than max days', () {
        expect(
          FormValidators.validateLeaveDays('15', 10),
          isNotNull,
        );
      });

      test('returns error for zero or negative days', () {
        expect(
          FormValidators.validateLeaveDays('0', 10),
          isNotNull,
        );
      });
    });

    group('validateDateRange', () {
      test('returns null for valid date range', () {
        final start = DateTime(2026, 5, 1);
        final end = DateTime(2026, 5, 10);
        expect(
          FormValidators.validateDateRange(start, end),
          isNull,
        );
      });

      test('returns error when end is before start', () {
        final start = DateTime(2026, 5, 10);
        final end = DateTime(2026, 5, 1);
        expect(
          FormValidators.validateDateRange(start, end),
          isNotNull,
        );
      });
    });
  });
}
