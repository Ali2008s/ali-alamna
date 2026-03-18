import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:streamit_laravel/screens/dashboard/dashboard_controller.dart';
import 'package:streamit_laravel/screens/dashboard/components/menu.dart';
import 'package:streamit_laravel/screens/matches/yacine_api.dart';

class MiniMatchesWidget extends StatefulWidget {
  const MiniMatchesWidget({super.key});

  @override
  State<MiniMatchesWidget> createState() => _MiniMatchesWidgetState();
}

class _MiniMatchesWidgetState extends State<MiniMatchesWidget> {
  Future<List<Map<String, dynamic>>>? _matchesFuture;
  final FocusNode _widgetFocus = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _matchesFuture = YacineApiService.getYacineMatches();
  }

  @override
  void dispose() {
    _widgetFocus.dispose();
    super.dispose();
  }

  void _goToMatches() {
    try {
      final dashCont = Get.find<DashboardController>();
      dashCont.onBottomTabChange(BottomItem.matches);
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _matchesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmer();
          }
          final matches = snapshot.data ?? [];
          if (matches.isEmpty) return const SizedBox.shrink();

          // Show up to 3 upcoming or live matches
          final preview = matches
              .where((m) => m['status'] != 'إنتهت المباراة')
              .take(3)
              .toList();

          if (preview.isEmpty) return const SizedBox.shrink();

          return Focus(
            focusNode: _widgetFocus,
            onFocusChange: (f) => setState(() => _isFocused = f),
            onKeyEvent: (_, event) {
              if (event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.select ||
                      event.logicalKey == LogicalKeyboardKey.enter)) {
                _goToMatches();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: GestureDetector(
              onTap: _goToMatches,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isFocused
                        ? [const Color(0xFF2D2B6B), const Color(0xFF1A1842)]
                        : [const Color(0xFF141420), const Color(0xFF0F0F1A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isFocused
                        ? const Color(0xFF4C46E8)
                        : Colors.white.withOpacity(0.08),
                    width: _isFocused ? 1.5 : 1,
                  ),
                  boxShadow: _isFocused
                      ? [
                          BoxShadow(
                            color: const Color(0xFF4C46E8).withOpacity(0.35),
                            blurRadius: 16,
                            spreadRadius: 1,
                          )
                        ]
                      : [],
                ),
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: Row(
                        children: [
                          const Icon(Icons.sports_soccer, color: Color(0xFF4C46E8), size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'مباريات اليوم',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4C46E8).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF4C46E8).withOpacity(0.5)),
                            ),
                            child: const Row(
                              children: [
                                Text(
                                  'المزيد',
                                  style: TextStyle(color: Color(0xFF4C46E8), fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.chevron_right, color: Color(0xFF4C46E8), size: 14),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(color: Colors.white.withOpacity(0.06), height: 1),
                    ...preview.map((m) => _buildMiniMatchRow(m)).toList(),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMiniMatchRow(Map<String, dynamic> m) {
    final isLive = m['status'] == 'جارية الآن';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          // Status
          SizedBox(
            width: 70,
            child: isLive
                ? Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      const Text('مباشر', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  )
                : Text(
                    m['status'] ?? '',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
          ),

          // Team 1
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    m['team_1_name'] ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                _miniLogo(m['team_1_logo'] ?? ''),
              ],
            ),
          ),

          // VS divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'vs',
              style: TextStyle(
                color: isLive ? Colors.red.withOpacity(0.7) : Colors.white30,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Team 2
          Expanded(
            child: Row(
              children: [
                _miniLogo(m['team_2_logo'] ?? ''),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    m['team_2_name'] ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniLogo(String url) {
    if (url.isEmpty) return const Icon(Icons.sports_soccer, color: Colors.white30, size: 22);
    return CachedNetworkImage(
      imageUrl: url,
      height: 22,
      width: 22,
      fit: BoxFit.contain,
      errorWidget: (_, __, ___) => const Icon(Icons.sports_soccer, color: Colors.white30, size: 22),
    );
  }

  Widget _buildShimmer() {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: const Color(0xFF141420),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF4C46E8), strokeWidth: 2),
      ),
    );
  }
}
