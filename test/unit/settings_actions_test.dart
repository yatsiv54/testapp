import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

void main() {
  test('SettingsActions uses correct Privacy Policy URL', () async {
    final file = File('lib/ui/settings/settings_actions.dart');
    final content = await file.readAsString();
    expect(content.contains('https://google.com'), isTrue, reason: 'Must use exactly https://google.com for Privacy Policy');
  });

  test('SettingsActions uses correct Share App string', () async {
    final file = File('lib/ui/settings/settings_actions.dart');
    final content = await file.readAsString();
    expect(content.contains('Try this app! :) {APPSTORE_LINK}'), isTrue, reason: 'Must use exactly the required share string');
  });
}
