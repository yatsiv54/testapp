import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tz_app_2_salary_leftovers_collector/ui/screens/profile_screen.dart';
import 'package:tz_app_2_salary_leftovers_collector/viewmodels/profile_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ProfileScreen shows Skip button when isInitialSetup is true', (WidgetTester tester) async {
    final profileVm = ProfileViewModel();
    
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<ProfileViewModel>.value(
          value: profileVm,
          child: const ProfileScreen(isInitialSetup: true),
        ),
      ),
    );

    expect(find.text('Skip for now'), findsOneWidget);
  });

  testWidgets('ProfileScreen hides Skip button when isInitialSetup is false', (WidgetTester tester) async {
    final profileVm = ProfileViewModel();
    
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<ProfileViewModel>.value(
          value: profileVm,
          child: const ProfileScreen(isInitialSetup: false),
        ),
      ),
    );

    expect(find.text('Skip for now'), findsNothing);
  });
}
