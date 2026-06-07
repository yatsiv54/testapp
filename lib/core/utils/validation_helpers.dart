class ValidationHelpers {
  static String? validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Field is required';
    }
    return null;
  }

  static String? validateText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Field is required';
    }
    final val = value.trim();
    if (val.length < 2) {
      return 'Must be at least 2 characters';
    }
    if (val.length > 40) {
      return 'Cannot exceed 40 characters';
    }
    final regex = RegExp(r'^[a-zA-Z0-9\s-]+$');
    if (!regex.hasMatch(val)) {
      return 'Invalid text input (only letters, numbers, spaces, dashes)';
    }
    return null;
  }

  static String? validateOptionalText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return validateText(value);
  }

  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Field is required';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return 'Invalid amount';
    }
    if (number <= 0) {
      return 'Must be a positive number';
    }
    if (value.split('.')[0].length > 6) {
      return 'Amount too large (max 6 digits)';
    }
    return null;
  }

  static String? validateDate(DateTime? date) {
    if (date == null) {
      return 'Date is required';
    }
    if (date.isAfter(DateTime.now())) {
      return 'Date cannot be in the future';
    }
    return null;
  }
}
