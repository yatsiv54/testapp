import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tz_app_2_salary_leftovers_collector/ui/screens/wheel_screen.dart';
import 'package:tz_app_2_salary_leftovers_collector/viewmodels/home_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('WheelScreen multiplier is strictly between 1.1x and 2.0x', (WidgetTester tester) async {
    final homeVm = HomeViewModel();
    // Pre-load with dummy profile and leftovers so there is a base to multiply
    await homeVm.updateLeftovers(100.0); // Now leftovers is 100.0

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<HomeViewModel>.value(
          value: homeVm,
          child: const WheelScreen(),
        ),
      ),
    );

    expect(find.text('Spin Now!'), findsOneWidget);
    
    await tester.tap(find.text('Spin Now!'));
    
    // Pump frames to finish 3 seconds animation
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // After animation, an AlertDialog should appear
    expect(find.byType(AlertDialog), findsOneWidget);

    // Get the Text widget that contains the multiplier message
    final Text textWidget = tester.widget(find.textContaining('You multiplied your leftovers by'));
    final String content = textWidget.data!;

    // Extract multiplier from 'You multiplied your leftovers by 1.45x!'
    final regex = RegExp(r'by (\d+\.\d+)x!');
    final match = regex.firstMatch(content);
    expect(match, isNotNull);

    final double multiplier = double.parse(match!.group(1)!);

    // Assert strictly between 1.1 and 2.0
    expect(multiplier >= 1.1 && multiplier <= 2.0, isTrue, reason: 'Multiplier $multiplier must be between 1.1 and 2.0');
    
    // Assert leftovers have been updated in ViewModel correctly
    // 100 * (multiplier - 1.0) is the bonus. New leftovers should be 100 + bonus.
    // Floating point precision might differ slightly, so we use closeTo
    final double expectedLeftovers = 100.0 * multiplier;
    expect(homeVm.leftovers, closeTo(expectedLeftovers, 0.5));
  });
}
