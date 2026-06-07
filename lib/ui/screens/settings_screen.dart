import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui';
import '../settings/settings_actions.dart';
import '../../viewmodels/settings_viewmodel.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/notification_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<SettingsViewModel>(context);

    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Settings'),
            floating: true,
            pinned: true,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Functional', style: TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ListTile(
            title: const Text('Currency'),
            trailing: DropdownButton<String>(
              value: vm.currency,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'USD', child: Text('USD (\$)', style: TextStyle(fontSize: 14))),
                DropdownMenuItem(value: 'EUR', child: Text('EUR (€)', style: TextStyle(fontSize: 14))),
              ],
              onChanged: (val) {
                if (val != null) vm.setCurrency(val);
              },
            ),
          ),
          SwitchListTile(
            title: const Text('Advanced Analytics'),
            subtitle: const Text('Show detailed charts on Analytics screen'),
            value: vm.advancedAnalytics,
            onChanged: (val) => vm.setAdvancedAnalytics(val),
            activeTrackColor: AppColors.primaryAccent,
          ),
          SwitchListTile(
            title: const Text('Require Photo Fixation'),
            subtitle: const Text('Make photo mandatory for expenses'),
            value: vm.requirePhoto,
            onChanged: (val) => vm.setRequirePhoto(val),
            activeTrackColor: AppColors.primaryAccent,
          ),
          ListTile(
            title: const Text('Clear Local Data'),
            leading: const Icon(Icons.delete_forever, color: AppColors.error),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear All Data?'),
                  content: const Text('This will delete all expenses and profile data permanently.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear', style: TextStyle(color: AppColors.error))),
                  ],
                ),
              );
              if (confirm == true) {
                await vm.clearAllData();
              }
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('System', style: TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ListTile(
            title: const Text('Theme Mode'),
            trailing: DropdownButton<String>(
              value: vm.themeMode,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'light', child: Text('Light', style: TextStyle(fontSize: 14))),
                DropdownMenuItem(value: 'dark', child: Text('Dark', style: TextStyle(fontSize: 14))),
              ],
              onChanged: (val) {
                if (val != null) vm.setThemeMode(val);
              },
            ),
          ),
          ListTile(
            title: const Text('Notifications'),
            subtitle: const Text('Manage daily reminders'),
            trailing: const Icon(Icons.notifications),
            onTap: () async {
              await SettingsActions.requestNotificationsPermission();
              // After permission is managed, we could initialize/cancel notifications
              final status = await Permission.notification.status;
              if (status.isGranted) {
                vm.setNotificationsEnabled(true);
                await NotificationService().scheduleDailyReminders();
              } else {
                vm.setNotificationsEnabled(false);
                await NotificationService().cancelAllNotifications();
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share App'),
            onTap: () {
              SettingsActions.shareApp();
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            onTap: () {
              SettingsActions.openPrivacyPolicy();
            },
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Rate App'),
            onTap: () {
              SettingsActions.rateApp();
            },
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            trailing: Text('1.0.0+1'),
          ),
          const SizedBox(height: 120),
            ]),
          ),
        ],
      ),
    );
  }
}
