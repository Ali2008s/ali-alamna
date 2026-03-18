import 'dart:convert';
import 'package:http/http.dart' as http;

class TelegramStorageService {
  static const String _botToken = '8611923680:AAEP67ncVYEykIsagjlIYNgEMTNvBjnQZcc';

  /// الحصول على الرابط المباشر للملف باستخدام file_id من واجهة برمجة تيليجرام
  /// ملاحظة: الروابط الخاصة بتيليجرام صالحة لساعة واحدة، لذا يجب جلبها عند التشغيل.
  static Future<String> getFileUrl(String fileId) async {
    if (fileId.isEmpty) return '';
    try {
      final url = Uri.parse('https://api.telegram.org/bot$_botToken/getFile?file_id=$fileId');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok'] == true) {
          final filePath = data['result']['file_path'];
          return 'https://api.telegram.org/file/bot$_botToken/$filePath';
        }
      }
    } catch (e) {
      print('Telegram Storage Error: $e');
    }
    return '';
  }
}
