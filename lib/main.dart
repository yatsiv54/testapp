import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/expenses_list_viewmodel.dart';
import 'viewmodels/profile_viewmodel.dart';
import 'viewmodels/settings_viewmodel.dart';
import 'ui/screens/preloader_screen.dart';
import 'core/utils/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsViewModel()..loadSettings()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()..loadData()),
        ChangeNotifierProvider(create: (_) => ExpensesListViewModel()..loadExpenses()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
      ],
      child: Consumer<SettingsViewModel>(
        builder: (context, settingsVm, child) {
          return MaterialApp(
            title: 'Salary Leftovers Collector',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settingsVm.themeMode == 'dark' ? ThemeMode.dark : ThemeMode.light,
            debugShowCheckedModeBanner: false,
            home: const PreloaderScreen(),
          );
        },
      ),
    );
  }
}
