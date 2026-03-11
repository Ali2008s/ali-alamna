import 'package:firebase_database/firebase_database.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/screens/live_tv/model/live_tv_dashboard_response.dart';

/// خدمة لجلب القنوات من Firebase Realtime Database
/// مسار البيانات: /channels/{id}
/// كل قناة تحتوي: categoryId, logoUrl, name, order, sources
class FirebaseChannelService {
  static final FirebaseDatabase _db = FirebaseDatabase.instance;

  /// يجلب جميع القنوات من Firebase مجمّعة حسب categoryId
  static Future<LiveChannelDashboardResponse>
      getLiveDashboardFromFirebase() async {
    try {
      // جلب القنوات
      final channelsSnapshot = await _db.ref('channels').get();
      // جلب التصنيفات
      final categoriesSnapshot = await _db.ref('categories').get();

      Map<String, String> categoryNames = {};
      if (categoriesSnapshot.exists && categoriesSnapshot.value != null) {
        final catMap =
            Map<String, dynamic>.from(categoriesSnapshot.value as Map);
        catMap.forEach((key, value) {
          if (value is Map) {
            final String name = value['name']?.toString() ?? key;
            categoryNames[key] = name;
          }
        });
      }

      if (!channelsSnapshot.exists || channelsSnapshot.value == null) {
        return LiveChannelDashboardResponse(data: LiveChannelModel());
      }

      final raw = Map<String, dynamic>.from(channelsSnapshot.value as Map);

      // تجميع القنوات حسب categoryId
      Map<String, List<ChannelModel>> categoryMap = {};
      int globalId = 1;

      raw.forEach((key, value) {
        if (value is! Map) return;
        final channelData = Map<String, dynamic>.from(value);

        final String categoryId =
            channelData['categoryId']?.toString() ?? 'uncategorized';
        final String name = channelData['name']?.toString() ?? '';
        final String logoUrl = channelData['logoUrl']?.toString() ?? '';

        // جلب أول source متاح
        String serverUrl = '';
        String streamType = 'url';
        if (channelData['sources'] is Map) {
          final sources =
              Map<String, dynamic>.from(channelData['sources'] as Map);
          if (sources.isNotEmpty) {
            final firstSource = sources.values.first;
            if (firstSource is Map) {
              serverUrl = firstSource['url']?.toString() ?? '';
              streamType = firstSource['type']?.toString() ?? 'url';
            } else {
              serverUrl = firstSource.toString();
            }
          }
        }

        final channel = ChannelModel(
          id: globalId++,
          name: name,
          posterTvImage: logoUrl,
          serverUrl: serverUrl,
          streamType: streamType,
          status: 1,
          access: 'free',
          category: categoryId,
        );

        categoryMap.putIfAbsent(categoryId, () => []).add(channel);
      });

      // بناء قائمة التصنيفات مع قنواتها
      List<CategoryData> categories = [];
      int catId = 1;
      categoryMap.forEach((catKey, channels) {
        final String catName = categoryNames[catKey] ?? catKey;
        categories.add(CategoryData(
          id: catId++,
          name: catName,
          channelData: channels,
          status: 1,
        ));
      });

      // ترتيب التصنيفات
      categories.sort((a, b) => a.name.compareTo(b.name));

      // أول 5 قنوات كـ slider
      List<ChannelModel> sliderChannels = [];
      for (var cat in categories) {
        sliderChannels.addAll(cat.channelData.take(2));
        if (sliderChannels.length >= 5) break;
      }

      return LiveChannelDashboardResponse(
        status: true,
        data: LiveChannelModel(
          slider: sliderChannels.take(5).toList(),
          categoryData: categories,
        ),
      );
    } catch (e) {
      log('FirebaseChannelService error: $e');
      return LiveChannelDashboardResponse(data: LiveChannelModel());
    }
  }
}
