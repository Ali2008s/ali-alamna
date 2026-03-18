import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class YacineApiService {
  static Future<List<Map<String, dynamic>>> getYacineMatches() async {
    try {
      final url = Uri.parse('https://a2.apk-api.com/api/events');
      final response = await http.get(url, headers: {
        'Accept': 'application/json',
        'User-Agent': 'okhttp/4.12.0',
        'api_url': 'http://ver3.yacinelive.com'
      });
      
      if (response.statusCode != 200) return [];
      
      final tHeader = response.headers['t'] ?? '';
      if (tHeader.isEmpty) return [];
      
      final d = base64Decode(response.body);
      final key = utf8.encode('c!xZj+N9&G@Ev@vw' + tHeader);
      
      List<int> p = List.filled(d.length, 0);
      for (int i = 0; i < d.length; i++) {
        p[i] = d[i] ^ key[i % key.length];
      }
      
      String decodedStr = utf8.decode(p).replaceAll('\\/', '/');
      
      final Map<String, dynamic> responseMap = jsonDecode(decodedStr);
      final List<dynamic> tableRows = responseMap['data'] ?? [];
      
      List<Map<String, dynamic>> teamData = [];
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      for (var row in tableRows) {
        Map<String, dynamic> teamEntry = {};
        
        num startNum = row['start_time'] ?? 0;
        num endNum = row['end_time'] ?? 0;
        
        int start = startNum.toInt();
        int end = endNum.toInt();
        
        String status = '';
        if (currentTime >= start && currentTime <= end) {
          status = 'جارية الآن';
        } else if (currentTime < start) {
          final startDate = DateTime.fromMillisecondsSinceEpoch(start * 1000);
          final sdf = DateFormat('hh:mm a', 'en_US');
          status = sdf.format(startDate);
        } else {
          status = 'إنتهت المباراة';
        }
        
        final dateObj = DateTime.fromMillisecondsSinceEpoch(start * 1000);
        final dateFormat = DateFormat('EEEE d', 'en_US');
        String matchDate = dateFormat.format(dateObj);
        
        teamEntry['id'] = row['id'];
        teamEntry['start_time'] = start;
        teamEntry['end_time'] = end;
        teamEntry['champions'] = row['champions'] ?? 'مباراة مباشرة';
        teamEntry['commentary'] = row['commentary'] ?? '';
        teamEntry['channel'] = row['channel'] ?? '';
        teamEntry['status'] = status;
        teamEntry['date'] = matchDate;
        
        final team1 = row['team_1'] ?? {};
        final team2 = row['team_2'] ?? {};
        
        teamEntry['team_1_name'] = team1['name'] ?? '';
        teamEntry['team_1_logo'] = team1['logo'] ?? '';
        teamEntry['team_2_name'] = team2['name'] ?? '';
        teamEntry['team_2_logo'] = team2['logo'] ?? '';
        
        teamEntry['channels'] = row['channels'] ?? [];
        teamEntry['url'] = row['url'];
        
        teamData.add(teamEntry);
      }
      
      return teamData;
    } catch (e) {
      print('Yacine API error: $e');
      // Return one dummy match so the user sees something is working but API is blocked
      return [{
        'id': 0,
        'team_1_name': 'فشل الاتصال',
        'team_2_name': 'تحقق من الشبكة',
        'team_1_logo': '',
        'team_2_logo': '',
        'status': 'خطأ في جلب البيانات',
        'champions': 'تأكد من إتاحة الوصول لهذا الرابط في بلدك',
        'date': 'اليوم',
        'commentary': 'API Error',
        'channels': []
      }];
    }
  }

  static Future<List<Map<String, dynamic>>> getServers(String matchId) async {
    try {
      final id = matchId.replaceAll('api_', '');
      if (id.isEmpty) return [];
      
      final url = Uri.parse('https://a2.apk-api.com/api/event/$id');
      final response = await http.get(url, headers: {
        'Accept': 'application/json',
        'User-Agent': 'okhttp/4.12.0',
        'api_url': 'http://ver3.yacinelive.com'
      });
      
      if (response.statusCode != 200) return [];
      
      final tHeader = response.headers['t'] ?? '';
      if (tHeader.isEmpty) return [];
      
      final d = base64Decode(response.body);
      final key = utf8.encode('c!xZj+N9&G@Ev@vw' + tHeader);
      
      List<int> p = List.filled(d.length, 0);
      for (int i = 0; i < d.length; i++) {
        p[i] = d[i] ^ key[i % key.length];
      }
      
      String decodedStr = utf8.decode(p).replaceAll('\\/', '/');
      final Map<String, dynamic> data = jsonDecode(decodedStr);
      
      List<Map<String, dynamic>> servers = [];
      if (data['data'] != null) {
        var payload = data['data'];
        List links = [];
        
        if (payload is List) {
          if (payload.isNotEmpty && payload[0] is Map) {
            links = payload;
          }
        } else if (payload is Map) {
          if (payload['links'] != null) links = payload['links'];
          else if (payload['servers'] != null) links = payload['servers'];
          else if (payload['players'] != null) links = payload['players'];
          else if (payload['video_links'] != null) links = payload['video_links'];
        }
        
        for (int i = 0; i < links.length; i++) {
          var link = links[i];
          if (link is! Map) continue;
          
          String sUrl = link['url'] ?? link['link'] ?? '';
          String sUa = link['user_agent'] ?? link['userAgent'] ?? '';
          var sHeaders = link['headers'] ?? {};
          
          if (sUrl.isNotEmpty) {
            servers.add({
              'name': link['name'] ?? link['quality'] ?? 'سيرفر ${i + 1}',
              'url': sUrl,
              'ua': sUa,
              'headers': base64Encode(utf8.encode(jsonEncode(sHeaders))),
            });
          }
        }
      }
      
      return servers;
    } catch (e) {
      print('Yacine Servers API error: $e');
      return [];
    }
  }
}
