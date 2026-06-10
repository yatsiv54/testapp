import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui';
import '../settings/settings_actions.dart';
import '../../viewmodels/settings_viewmodel.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/notification_service.dart';
import '../widgets/loading_shimmer_widget.dart';
import 'profile_screen.dart';
import '../widgets/error_state_widget.dart';
import '../../dev_test/dev_test.dart';
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<SettingsViewModel>(context);

    if (vm.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const LoadingShimmerWidget(type: ShimmerType.settings),
      );
    }

    if (vm.hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: ErrorStateWidget(
          message: vm.errorMessage ?? 'Failed to load settings',
          onRetry: () => vm.loadSettings(),
        ),
      );
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
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionTitle('Profile'),
                _buildCard([
                  ListTile(
                    title: const Text('Edit Profile'),
                    leading: const Icon(Icons.person, color: AppColors.primaryAccent),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.primaryAccent),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProfileScreen(isInitialSetup: false)),
                      );
                    },
                  ),
                ]),
                const SizedBox(height: 24),
                _buildSectionTitle('Functional'),
                _buildCard([
                  ListTile(
                    title: const Text('Currency'),
                    leading: const Icon(Icons.attach_money, color: AppColors.primaryAccent),
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
                  const Divider(height: 1, indent: 56),
                  SwitchListTile(
                    title: const Text('Advanced Analytics'),
                    subtitle: const Text('Show detailed charts on Analytics screen'),
                    secondary: const Icon(Icons.analytics, color: AppColors.primaryAccent),
                    value: vm.advancedAnalytics,
                    onChanged: (val) => vm.setAdvancedAnalytics(val),
                    activeTrackColor: AppColors.primaryAccent,
                  ),
                  const Divider(height: 1, indent: 56),
                  SwitchListTile(
                    title: const Text('Require Photo Fixation'),
                    subtitle: const Text('Make photo mandatory for expenses'),
                    secondary: const Icon(Icons.camera_alt, color: AppColors.primaryAccent),
                    value: vm.requirePhoto,
                    onChanged: (val) => vm.setRequirePhoto(val),
                    activeTrackColor: AppColors.primaryAccent,
                  ),
                ]),
                const SizedBox(height: 24),
                _buildSectionTitle('System'),
                _buildCard([
                  ListTile(
                    title: const Text('Theme Mode'),
                    leading: const Icon(Icons.palette, color: AppColors.primaryAccent),
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
                  const Divider(height: 1, indent: 56),
                  SwitchListTile(
                    title: const Text('Notifications'),
                    secondary: const Icon(Icons.notifications, color: AppColors.primaryAccent),
                    value: vm.notificationsEnabled,
                    onChanged: (val) async {
                      if (val) {
                        final status = await Permission.notification.request();
                        if (status.isGranted) {
                          await vm.setNotificationsEnabled(true);
                          await NotificationService().scheduleDailyReminders();
                        } else {
                          await vm.setNotificationsEnabled(false);
                          if (context.mounted) {
                            if (status.isPermanentlyDenied) {
                              final goToSettings = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Notifications Denied'),
                                  content: const Text('Please grant Notifications access in Settings to receive reminders.'),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Open Settings')),
                                  ],
                                ),
                              );
                              if (goToSettings == true) {
                                openAppSettings();
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifications permission denied.')));
                            }
                          }
                        }
                      } else {
                        await vm.setNotificationsEnabled(false);
                        await NotificationService().cancelAllNotifications();
                      }
                    },
                    activeTrackColor: AppColors.primaryAccent,
                  ),
                ]),
                const SizedBox(height: 24),
                _buildSectionTitle('More'),
                _buildCard([
                  ListTile(
                    leading: const Icon(Icons.share, color: AppColors.primaryAccent),
                    title: const Text('Share App'),
                    onTap: () {
                      DevTest.shareApp(context);
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip, color: AppColors.primaryAccent),
                    title: const Text('Privacy Policy'),
                    onTap: () {
                      DevTest.openPrivacyPolicy();
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.description, color: AppColors.primaryAccent),
                    title: const Text('Terms of Service'),
                    onTap: () {
                      SettingsActions.openTermsOfService();
                    },
                  ),
                ]),
                const SizedBox(height: 24),
                _buildSectionTitle('Danger Zone'),
                _buildCard([
                  ListTile(
                    title: const Text('Clear Local Data', style: TextStyle(color: AppColors.error)),
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
                ]),
                const SizedBox(height: 120),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }
}
