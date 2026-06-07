class CurrencyHelper {
  static String getSymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'UAH':
        return '₴';
      default:
        return currencyCode;
    }
  }
}
