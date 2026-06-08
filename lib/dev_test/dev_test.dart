import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class DevTest {
  /// Opens the Privacy Policy URL using url_launcher
  static Future<void> openPrivacyPolicy() async {
    final Uri url = Uri.parse('https://google.com');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  /// Shares the app using share_plus
  static Future<void> shareApp() async {
    const String shareText = 'Try this app! :) {APPSTORE_LINK}';
    await Share.share(shareText);
  }
}
