import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tz_app_2_salary_leftovers_collector/data/services/local_storage_service.dart';

void main() {
  late LocalStorageService storage;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorageService();
  });

  test('LocalStorageService saves and retrieves settings correctly', () async {
    // Default values
    expect(await storage.getCurrency(), 'USD');
    expect(await storage.getNotificationsEnabled(), false);
    expect(await storage.getAdvancedAnalytics(), false);
    expect(await storage.getRequirePhoto(), true);
    expect(await storage.getThemeMode(), 'light');

    // Update values
    await storage.saveCurrency('EUR');
    await storage.setNotificationsEnabled(true);
    await storage.setAdvancedAnalytics(true);
    await storage.setRequirePhoto(false);
    await storage.setThemeMode('dark');

    // Verify
    expect(await storage.getCurrency(), 'EUR');
    expect(await storage.getNotificationsEnabled(), true);
    expect(await storage.getAdvancedAnalytics(), true);
    expect(await storage.getRequirePhoto(), false);
    expect(await storage.getThemeMode(), 'dark');
  });
}
