import 'package:flutter_test/flutter_test.dart';
import 'package:tz_app_2_salary_leftovers_collector/core/utils/validation_helpers.dart';

void main() {
  group('ValidationHelpers - Text Inputs', () {
    test('Valid text passes validation', () {
      expect(ValidationHelpers.validateText('Groceries'), isNull);
      expect(ValidationHelpers.validateText('A valid text-with dash'), isNull);
    });

    test('Empty or null text fails validation', () {
      expect(ValidationHelpers.validateText(''), 'Field is required');
      expect(ValidationHelpers.validateText(null), 'Field is required');
    });

    test('Text too short fails validation (min 2 chars)', () {
      expect(ValidationHelpers.validateText('A'), 'Must be at least 2 characters');
    });

    test('Text too long fails validation (max 40 chars)', () {
      final longText = 'A' * 41;
      expect(ValidationHelpers.validateText(longText), 'Cannot exceed 40 characters');
    });

    test('Text with special characters fails validation', () {
      expect(ValidationHelpers.validateText('Hello@World'), 'Invalid text input (only letters, numbers, spaces, dashes)');
      expect(ValidationHelpers.validateText('Groceries!'), 'Invalid text input (only letters, numbers, spaces, dashes)');
    });
  });

  group('ValidationHelpers - Numeric Inputs', () {
    test('Valid positive amount passes validation', () {
      expect(ValidationHelpers.validateAmount('150.50'), isNull);
      expect(ValidationHelpers.validateAmount('5'), isNull);
      expect(ValidationHelpers.validateAmount('999999'), isNull);
    });

    test('Empty or null amount fails validation', () {
      expect(ValidationHelpers.validateAmount(''), 'Field is required');
      expect(ValidationHelpers.validateAmount(null), 'Field is required');
    });

    test('Non-numeric input fails validation', () {
      expect(ValidationHelpers.validateAmount('abc'), 'Invalid amount');
      expect(ValidationHelpers.validateAmount('12a.5'), 'Invalid amount');
    });

    test('Negative or zero amount fails validation', () {
      expect(ValidationHelpers.validateAmount('-10'), 'Must be a positive number');
      expect(ValidationHelpers.validateAmount('0'), 'Must be a positive number');
    });

    test('Amount exceeding 6 digits fails validation', () {
      expect(ValidationHelpers.validateAmount('1000000'), 'Amount too large (max 6 digits)');
      expect(ValidationHelpers.validateAmount('1234567.89'), 'Amount too large (max 6 digits)');
    });
  });
}
