import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';

import '../../components/cached_image_widget.dart';
import '../../main.dart';
import '../../utils/colors.dart';

/// موديل مباراة
class MatchModel {
  final String id;
  final String team1Name;
  final String team1Logo;
  final String team2Name;
  final String team2Logo;
  final String champions;
  final String commentary;
  final String channel;
  final String status;
  final String date;
  final int startTime;
  final int endTime;

  MatchModel({
    required this.id,
    required this.team1Name,
    required this.team1Logo,
    required this.team2Name,
    required this.team2Logo,
    required this.champions,
    required this.commentary,
    required this.channel,
    required this.status,
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  bool get isLive {
    final current = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return current >= startTime && current <= endTime;
  }
}

class MatchScheduleController extends GetxController {
  RxList<MatchModel> matches = <MatchModel>[].obs;
  RxMap<String, List<MatchModel>> groupedMatches = <String, List<MatchModel>>{}.obs;
  RxBool isLoading = true.obs;
  RxString errorMsg = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchMatches();
  }

  Future<void> fetchMatches() async {
    isLoading(true);
    errorMsg('');
    try {
      final response = await http.get(
        Uri.parse('https://a2.apk-api.com/api/events'),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'okhttp/4.12.0',
          'api_url': 'http://ver3.yacinelive.com',
        },
      ).timeout(const Duration(seconds: 20));

      final tHeader = response.headers['t'] ?? '';
      final decoded = _decryptResponse(response.body, tHeader);
      if (decoded.isEmpty) throw Exception('فشل فك تشفير البيانات');

      final json = jsonDecode(decoded) as Map<String, dynamic>;
      final List tableRows = json['data'] as List? ?? [];

      final int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      List<MatchModel> result = [];
      for (final row in tableRows) {
        if (row is! Map<String, dynamic>) continue;

        final int start = (row['start_time'] as num?)?.toInt() ?? 0;
        final int end = (row['end_time'] as num?)?.toInt() ?? 0;

        String status;
        if (currentTime >= start && currentTime <= end) {
          status = 'جارية الآن';
        } else if (currentTime < start) {
          final startDt = DateTime.fromMillisecondsSinceEpoch(start * 1000);
          final h = startDt.hour.toString().padLeft(2, '0');
          final m = startDt.minute.toString().padLeft(2, '0');
          final period = startDt.hour < 12 ? 'AM' : 'PM';
          final hour12 = startDt.hour % 12 == 0 ? 12 : startDt.hour % 12;
          status = '${hour12.toString().padLeft(2, '0')}:$m $period';
        } else {
          status = 'انتهت المباراة';
        }

        final dateObj = DateTime.fromMillisecondsSinceEpoch(start * 1000);
        final days = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];
        final matchDate = '${days[dateObj.weekday % 7]} ${dateObj.day}';

        final team1 = row['team_1'] as Map<String, dynamic>? ?? {};
        final team2 = row['team_2'] as Map<String, dynamic>? ?? {};

        result.add(MatchModel(
          id: row['id']?.toString() ?? '',
          startTime: start,
          endTime: end,
          champions: row['champions']?.toString() ?? '',
          commentary: row['commentary']?.toString() ?? '',
          channel: row['channel']?.toString() ?? '',
          status: status,
          date: matchDate,
          team1Name: team1['name']?.toString() ?? '',
          team1Logo: team1['logo']?.toString() ?? '',
          team2Name: team2['name']?.toString() ?? '',
          team2Logo: team2['logo']?.toString() ?? '',
        ));
      }

      matches.value = result;
      // تجميع حسب التاريخ
      final Map<String, List<MatchModel>> grouped = {};
      for (final m in result) {
        grouped.putIfAbsent(m.date, () => []).add(m);
      }
      groupedMatches.value = grouped;
    } catch (e) {
      errorMsg('فشل تحميل جدول المباريات: $e');
      log('fetchMatches error: $e');
    } finally {
      isLoading(false);
    }
  }

  String _decryptResponse(String response, String tHeader) {
    try {
      final Uint8List d = base64.decode(response);
      final List<int> k = ('c!xZj+N9\u0026G@Ev@vw$tHeader').codeUnits;
      final List<int> p = List<int>.filled(d.length, 0);
      for (int i = 0; i < d.length; i++) {
        p[i] = d[i] ^ k[i % k.length];
      }
      return String.fromCharCodes(p).replaceAll('\\/', '/');
    } catch (e) {
      log('decrypt error: $e');
      return '';
    }
  }
}

class MatchScheduleScreen extends StatelessWidget {
  MatchScheduleScreen({super.key});

  final MatchScheduleController controller = Get.put(MatchScheduleController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appScreenBackgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [appColorPrimary.withOpacity(0.3), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.sports_soccer, color: appColorPrimary, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'جدول المباريات',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Obx(() => controller.isLoading.value
                      ? const SizedBox.shrink()
                      : IconButton(
                          icon: Icon(Icons.refresh, color: appColorPrimary),
                          onPressed: controller.fetchMatches,
                        )),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: appColorPrimary),
                        const SizedBox(height: 16),
                        const Text('جاري تحميل المباريات...', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  );
                }

                if (controller.errorMsg.value.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text(controller.errorMsg.value, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: appColorPrimary),
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                          onPressed: controller.fetchMatches,
                        ),
                      ],
                    ),
                  );
                }

                if (controller.groupedMatches.isEmpty) {
                  return const Center(
                    child: Text('لا توجد مباريات متاحة', style: TextStyle(color: Colors.white70)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: controller.groupedMatches.keys.length,
                  itemBuilder: (context, i) {
                    final date = controller.groupedMatches.keys.elementAt(i);
                    final dayMatches = controller.groupedMatches[date] ?? [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date Header
                        Container(
                          margin: const EdgeInsets.only(top: 16, bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: appColorPrimary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: appColorPrimary.withOpacity(0.4)),
                          ),
                          child: Text(
                            date,
                            style: TextStyle(
                              color: appColorPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),

                        // Match Cards
                        ...dayMatches.map((match) => _MatchCard(match: match)),
                      ],
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final MatchModel match;

  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final bool isLive = match.isLive;
    final bool isFinished = match.status == 'انتهت المباراة';

    return Focus(
      child: Builder(builder: (context) {
        final hasFocus = Focus.of(context).hasFocus;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: hasFocus ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isLive
                  ? Colors.red.withOpacity(0.7)
                  : hasFocus
                      ? appColorPrimary
                      : Colors.white.withOpacity(0.1),
              width: hasFocus || isLive ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Championship + Status
                Row(
                  children: [
                    if (match.champions.isNotEmpty)
                      Expanded(
                        child: Text(
                          match.champions,
                          style: TextStyle(color: Colors.amber.shade300, fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLive
                            ? Colors.red.withOpacity(0.2)
                            : isFinished
                                ? Colors.grey.withOpacity(0.2)
                                : appColorPrimary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isLive ? Colors.red : isFinished ? Colors.grey : appColorPrimary,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isLive) ...[
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            match.status,
                            style: TextStyle(
                              color: isLive ? Colors.red : isFinished ? Colors.grey : appColorPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Teams Row
                Row(
                  children: [
                    // Team 1
                    Expanded(
                      child: Column(
                        children: [
                          _TeamLogo(url: match.team1Logo),
                          const SizedBox(height: 8),
                          Text(
                            match.team1Name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // VS
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'VS',
                        style: TextStyle(
                          color: isLive ? Colors.red : Colors.white54,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),

                    // Team 2
                    Expanded(
                      child: Column(
                        children: [
                          _TeamLogo(url: match.team2Logo),
                          const SizedBox(height: 8),
                          Text(
                            match.team2Name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Channel
                if (match.commentary.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.tv, color: Colors.white38, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        match.commentary,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _TeamLogo extends StatelessWidget {
  final String url;
  const _TeamLogo({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white12),
      ),
      child: url.isNotEmpty
          ? ClipOval(
              child: CachedImageWidget(
                url: url,
                width: 62,
                height: 62,
                fit: BoxFit.contain,
              ),
            )
          : const Icon(Icons.sports_soccer, color: Colors.white38, size: 30),
    );
  }
}
