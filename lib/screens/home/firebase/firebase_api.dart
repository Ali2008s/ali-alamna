import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:streamit_laravel/screens/home/model/dashboard_res_model.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';
import 'telegram_storage_service.dart';

class FirebaseChannelApi {
  static Future<List<CategoryListModel>> getFirebaseChannels() async {
    try {
      // Use direct REST API for better consistency across web/native
      final catResponse = await http.get(Uri.parse('https://hnd9-db536-default-rtdb.firebaseio.com/categories.json'));
      final chanResponse = await http.get(Uri.parse('https://hnd9-db536-default-rtdb.firebaseio.com/channels.json'));
      
      Map<String, String> categoryNames = {};
      if (catResponse.statusCode == 200 && catResponse.body != 'null') {
        final decoded = jsonDecode(catResponse.body);
        if (decoded is Map) {
          decoded.forEach((key, value) {
            if (value is Map) {
              categoryNames[key] = value['name']?.toString() ?? 'قسم غير معروف';
            }
          });
        }
      }

      if (chanResponse.statusCode == 200 && chanResponse.body != 'null') {
         final decoded = jsonDecode(chanResponse.body);
         if (decoded is! Map) return [];
         
         Map<String, dynamic> channelsMap = decoded as Map<String, dynamic>;
         Map<String, List<PosterDataModel>> groupedChannels = {};
         
         channelsMap.forEach((key, value) {
            if (value is! Map) return;
            String categoryId = value['categoryId']?.toString() ?? 'uncategorized';
            String categoryName = categoryNames[categoryId] ?? value['category']?.toString() ?? 'قنوات عامة';
            
            String name = value['name'] ?? 'قناة';
            String logo = value['logoUrl'] ?? value['logo'] ?? value['image'] ?? '';
            
            String url = '';
            if (value['sources'] != null && value['sources'] is List && (value['sources'] as List).isNotEmpty) {
               url = value['sources'][0]['url'] ?? '';
            } else if (value['Url'] != null) {
               url = value['Url'];
            }

            String typeUrl = 'hls';
            if (url.endsWith('.mp4')) {
              typeUrl = 'video';
            } else if (url.contains('youtu.be') || url.contains('youtube.com')) {
              typeUrl = 'youtube';
            } else if (url.contains('facebook.com')) {
               typeUrl = 'facebook';
            } else if (url.contains('m3u8')) {
              typeUrl = 'hls';
            } else if (url.contains('mpd')) {
              typeUrl = 'dash';
            } else if (url.contains('<iframe')) {
              typeUrl = 'embedded';
            }

            if (!groupedChannels.containsKey(categoryName)) {
               groupedChannels[categoryName] = [];
            }
            
            var channelDetails = ContentData(
              id: 0,
              name: name,
              thumbnailImage: logo,
              description: url, 
              type: 'livetv',
              trailerUrl: url,
              trailerUrlType: typeUrl,
              access: 'free_access',
              hasContentAccess: 1,
            );
            
            groupedChannels[categoryName]!.add(PosterDataModel(
               id: 0,
               posterImage: logo,
               details: channelDetails
            ));
         });
         
         List<CategoryListModel> sections = [];
         groupedChannels.forEach((catName, channels) {
            sections.add(CategoryListModel(
               name: catName,
               sectionType: 'channels_$catName',
               data: channels,
               showViewAll: false
            ));
         });
         
         return sections;
      }
    } catch (e) {
      print('Firebase HTTP error: $e');
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getShorts() async {
    try {
      final response = await http.get(Uri.parse('https://hnd9-db536-default-rtdb.firebaseio.com/Main/Shorts.json'));
      if (response.statusCode == 200 && response.body != 'null') {
        dynamic decodedData = jsonDecode(response.body);
        List<Map<String, dynamic>> shorts = [];

        if (decodedData is Map) {
          for (var entry in decodedData.entries) {
            String key = entry.key;
            var value = entry.value;

            if (value is Map) {
              String tgFileId = value['tg_file_id']?.toString() ?? '';
              String finalUrl = value['video_url'] ?? value['url'] ?? '';

              // If a Telegram file ID exists, renew the URL to avoid 1-hour expiration
              if (tgFileId.isNotEmpty) {
                 String freshUrl = await TelegramStorageService.getFileUrl(tgFileId);
                 if (freshUrl.isNotEmpty) {
                   finalUrl = freshUrl;
                 }
              }

              shorts.add({
                'video_url': finalUrl,
                'title': value['title'] ?? 'فيديو جديد',
                'likes': value['likes'] ?? 0,
                'comments': value['comments'] ?? 0,
                'account_name': value['account_name'] ?? 'عالمنا',
              });
            }
          }
        } else if (decodedData is List) {
          for (var value in decodedData) {
            if (value is Map) {
              String tgFileId = value['tg_file_id']?.toString() ?? '';
              String finalUrl = value['video_url'] ?? value['url'] ?? '';

              // If a Telegram file ID exists, renew the URL to avoid 1-hour expiration
              if (tgFileId.isNotEmpty) {
                 String freshUrl = await TelegramStorageService.getFileUrl(tgFileId);
                 if (freshUrl.isNotEmpty) {
                   finalUrl = freshUrl;
                 }
              }

              shorts.add({
                'video_url': finalUrl,
                'title': value['title'] ?? 'فيديو جديد',
                'likes': value['likes'] ?? 0,
                'comments': value['comments'] ?? 0,
                'account_name': value['account_name'] ?? 'عالمنا',
              });
            }
          }
        }
        return shorts;
      }
    } catch (e) {
      print('Firebase Shorts error: $e');
    }
    // No data - return empty list, UI shows proper empty state
    return [];
  }
}
