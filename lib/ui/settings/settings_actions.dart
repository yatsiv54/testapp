import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:in_app_review/in_app_review.dart';

class SettingsActions {
  static Future<void> openPrivacyPolicy() async {
    final Uri url = Uri.parse('https://google.com');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  static Future<void> shareApp() async {
    await Share.share('Try this app! :) {APPSTORE_LINK}');
  }
  
  static Future<void> requestNotificationsPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      final newStatus = await Permission.notification.request();
      if (newStatus.isPermanentlyDenied) {
        await openAppSettings();
      }
    } else if (status.isPermanentlyDenied || status.isGranted) {
      await openAppSettings();
    }
  }

  static Future<void> rateApp() async {
    final InAppReview inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      inAppReview.requestReview();
    }
  }
}
