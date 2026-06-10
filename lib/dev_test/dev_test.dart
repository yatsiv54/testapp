import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';

class DevTest {
  /// Opens the Privacy Policy URL using url_launcher
  static Future<void> openPrivacyPolicy() async {
    final Uri url = Uri.parse('https://google.com');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  /// Shares the app using share_plus
  static Future<void> shareApp(BuildContext context) async {
    const String shareText =
        'Try this app! :) {APPSTORE_LINK} Salary Leftovers Collector';

    // Provide a sharePositionOrigin for iPad support
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box != null) {
      await Share.share(
        shareText,
        sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
      );
    } else {
      await Share.share(shareText);
    }
  }
}
