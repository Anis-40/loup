import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class AppUpdater {
  static const String githubUsername = 'Anis-40';
  static const String githubRepo = 'loup';

  /// يتحقق من إصدار التطبيق بآخر إصدار على GitHub
  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$githubUsername/$githubRepo/releases/latest'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String latestTagName = data['tag_name'] ?? '';
        // نقوم بإزالة حرف v إن وجد، مثلاً v1.0.1 تصبح 1.0.1
        final latestVersion = latestTagName.replaceAll('v', '').trim();
        final String htmlUrl = data['html_url'] ?? '';

        if (_isNewerVersion(currentVersion, latestVersion)) {
          if (context.mounted) {
            _showUpdateDialog(context, latestVersion, htmlUrl);
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
  }

  /// تقارن الإصدارين، ترجع true إذا كان أحدث
  static bool _isNewerVersion(String current, String latest) {
    List<int> currParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      int c = i < currParts.length ? currParts[i] : 0;
      int l = i < latestParts.length ? latestParts[i] : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }

  static void _showUpdateDialog(BuildContext context, String newVersion, String url) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.success, width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.system_update_alt, color: AppColors.success),
            SizedBox(width: 10),
            Text('تحديث جديد متاح! 🎉', style: TextStyle(color: AppColors.gold, fontSize: 20)),
          ],
        ),
        content: Text(
          'تم إطلاق الإصدار ($newVersion) من لعبة الذيابة.\nهل ترغب في تحميل التحديث الآن للحصول على الميزات الجديدة؟',
          style: const TextStyle(color: AppColors.text, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('تجاهل حالياً', style: TextStyle(color: AppColors.textSecond)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final link = Uri.parse(url);
              if (await canLaunchUrl(link)) {
                await launchUrl(link, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text('تحميل التحديث', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
