import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/components/app_scaffold.dart';
import 'package:streamit_laravel/screens/dashboard/dashboard_controller.dart';
import 'package:streamit_laravel/screens/live_tv/live_tv_details/live_tv_details_screen.dart';
import 'package:streamit_laravel/screens/live_tv/model/live_tv_dashboard_response.dart';
import 'yacine_api.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ─── Leagues Data ─────────────────────────────────────────────────────────────
const List<Map<String, dynamic>> _kLeagues = [
  {'name': 'الكل', 'icon': 'https://cdn-icons-png.flaticon.com/128/53/53283.png'},
  {'name': 'Premier Lg', 'icon': 'https://upload.wikimedia.org/wikipedia/en/f/f2/Premier_League_Logo.svg'},
  {'name': 'La Liga', 'icon': 'https://upload.wikimedia.org/wikipedia/commons/1/13/LaLiga.svg'},
  {'name': 'Serie A', 'icon': 'https://upload.wikimedia.org/wikipedia/en/e/e1/Serie_A_logo_%282019%29.svg'},
  {'name': 'Bundesliga', 'icon': 'https://upload.wikimedia.org/wikipedia/en/d/df/Bundesliga_logo_%282017%29.svg'},
  {'name': 'Ligue 1', 'icon': 'https://upload.wikimedia.org/wikipedia/commons/e/e7/Ligue1.svg'},
];

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  _MatchesScreenState createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> with SingleTickerProviderStateMixin {
  Future<List<Map<String, dynamic>>>? matchesFuture;
  final FocusNode _screenFocusNode = FocusNode();
  String _selectedLeague = 'الكل';
  late TabController _tabController;
  final ScrollController _mainScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshMatches();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mainScroll.dispose();
    _screenFocusNode.dispose();
    super.dispose();
  }

  void _refreshMatches() {
    setState(() {
      matchesFuture = YacineApiService.getYacineMatches();
    });
  }

  List<Map<String, dynamic>> _filterByLeague(List<Map<String, dynamic>> matches) {
    if (_selectedLeague == 'الكل') return matches;
    return matches.where((m) {
      final champ = (m['champions'] ?? '').toString().toLowerCase();
      return champ.contains(_selectedLeague.toLowerCase());
    }).toList();
  }

  List<Map<String, dynamic>> _getLiveMatches(List<Map<String, dynamic>> matches) {
    return _filterByLeague(matches).where((m) => m['status'] == 'جارية الآن').toList();
  }

  List<Map<String, dynamic>> _getUpcomingMatches(List<Map<String, dynamic>> matches) {
    return _filterByLeague(matches).where((m) => m['status'] != 'جارية الآن' && m['status'] != 'إنتهت المباراة').toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffoldNew(
      hasLeadingWidget: false,
      hideAppBar: true,
      scaffoldBackgroundColor: const Color(0xFF0A0A0F),
      body: Focus(
        focusNode: _screenFocusNode,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            try {
              final dashCont = Get.find<DashboardController>();
              dashCont.bottomNavItems[dashCont.selectedBottomNavIndex.value].focusNode.requestFocus();
              return KeyEventResult.handled;
            } catch (e) {
              log('Matches navigation error: $e');
            }
          }
          return KeyEventResult.ignored;
        },
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: matchesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoading();
            }
            if (snapshot.hasError) {
              return _buildError();
            }
            final allMatches = snapshot.data ?? [];
            final liveMatches = _getLiveMatches(allMatches);
            final upcomingMatches = _getUpcomingMatches(allMatches);

            return CustomScrollView(
              controller: _mainScroll,
              slivers: [
                // App Bar
                SliverToBoxAdapter(child: _buildHeader()),

                // Search bar
                SliverToBoxAdapter(child: _buildSearchBar()),

                // Leagues row
                SliverToBoxAdapter(child: _buildLeaguesRow()),

                // Live Match Highlight (Big Card)
                if (liveMatches.isNotEmpty) ...[
                  SliverToBoxAdapter(child: _buildSectionTitle('🔴 مباشر الآن')),
                  SliverToBoxAdapter(child: _buildLiveHighlight(liveMatches.first)),
                ],

                // Upcoming header with tabs
                SliverToBoxAdapter(child: _buildSectionTitle('⏰ القادمة')),
                SliverToBoxAdapter(child: _buildLeagueTabsRow(allMatches)),

                // Upcoming matches list
                SliverToBoxAdapter(
                  child: _buildUpcomingList(upcomingMatches),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF4C46E8)),
          SizedBox(height: 16),
          Text('جاري تحميل المباريات...', style: TextStyle(color: Colors.white60, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, color: Colors.white24, size: 70),
          const SizedBox(height: 16),
          const Text('خطأ في تحميل المباريات', style: TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _refreshMatches,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4C46E8)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 55, 20, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF0A0A0F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.menu, color: Colors.white, size: 26),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Match Now',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          GestureDetector(
            onTap: _refreshMatches,
            child: const Icon(Icons.refresh, color: Colors.white70, size: 22),
          ),
          const SizedBox(width: 14),
          const Icon(Icons.chevron_left, color: Colors.white70),
          const Icon(Icons.calendar_today_outlined, color: Colors.white70, size: 20),
          const Icon(Icons.chevron_right, color: Colors.white70),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Row(
          children: [
            Icon(Icons.search, color: Colors.white38, size: 20),
            SizedBox(width: 10),
            Text('Search....', style: TextStyle(color: Colors.white38, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaguesRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: Text('Big Leagues', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _kLeagues.length,
            itemBuilder: (context, i) {
              final league = _kLeagues[i];
              final isSelected = _selectedLeague == league['name'];
              return GestureDetector(
                onTap: () => setState(() => _selectedLeague = league['name']),
                child: Container(
                  width: 70,
                  margin: const EdgeInsets.only(right: 8),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? const Color(0xFF4C46E8).withOpacity(0.15) : const Color(0xFF1E1E2E),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF4C46E8) : Colors.white10,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: league['icon'],
                            fit: BoxFit.contain,
                            errorWidget: (_, __, ___) => const Icon(Icons.sports_soccer, color: Colors.white54, size: 24),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        league['name'],
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF4C46E8) : Colors.white60,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLeagueTabsRow(List<Map<String, dynamic>> allMatches) {
    final leagues = {'جميع المباريات': 0, 'Premier League': 0, 'La Liga': 0, 'Serie A': 0, 'Bundesliga': 0};
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: leagues.keys.map((name) {
          final isSelected = name == 'جميع المباريات';
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF4C46E8) : const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              name,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLiveHighlight(Map<String, dynamic> match) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GestureDetector(
        onTap: () => _showServersDialog(context, match),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2D2B6B), Color(0xFF1A1842)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF4C46E8).withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4C46E8).withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    match['date'] ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        const Text('LIVE', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _buildTeamLogo(match['team_1_logo'] ?? '', size: 60),
                        const SizedBox(height: 8),
                        Text(
                          match['team_1_name'] ?? '',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            match['status'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.emoji_events, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                match['champions'] ?? '',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        _buildTeamLogo(match['team_2_logo'] ?? '', size: 60),
                        const SizedBox(height: 8),
                        Text(
                          match['team_2_name'] ?? '',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if ((match['commentary'] ?? '').isNotEmpty) ...[
                    const Icon(Icons.mic, color: Colors.white54, size: 14),
                    const SizedBox(width: 4),
                    Text(match['commentary'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    const Spacer(),
                  ] else
                    const Spacer(),
                  if ((match['channel'] ?? '').isNotEmpty) ...[
                    const Icon(Icons.live_tv, color: Colors.white54, size: 14),
                    const SizedBox(width: 4),
                    Text(match['channel'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingList(List<Map<String, dynamic>> matches) {
    if (matches.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text('لا توجد مباريات قادمة', style: TextStyle(color: Colors.white54, fontSize: 15)),
        ),
      );
    }
    return Column(
      children: matches.map((m) => _buildUpcomingCard(m)).toList(),
    );
  }

  Widget _buildUpcomingCard(Map<String, dynamic> m) {
    return _MatchFocusCard(match: m, onTap: () => _showServersDialog(context, m));
  }

  Widget _buildTeamLogo(String url, {double size = 50}) {
    if (url.isEmpty) {
      return Icon(Icons.sports_soccer, color: Colors.white54, size: size);
    }
    return CachedNetworkImage(
      imageUrl: url,
      height: size,
      width: size,
      fit: BoxFit.contain,
      errorWidget: (_, __, ___) => Icon(Icons.sports_soccer, color: Colors.white54, size: size * 0.8),
    );
  }

  void _showServersDialog(BuildContext context, Map<String, dynamic> match) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: Color(0xFF4C46E8))),
    );

    final servers = await YacineApiService.getServers(match['id'].toString());
    if (context.mounted) Navigator.pop(context);
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _buildTeamLogo(match['team_1_logo'] ?? '', size: 36),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${match['team_1_name']} vs ${match['team_2_name']}',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildTeamLogo(match['team_2_logo'] ?? '', size: 36),
                  ],
                ),
                const Divider(color: Colors.white12, height: 24),
                const Text('اختر السيرفر', style: TextStyle(color: Colors.white60, fontSize: 13)),
                const SizedBox(height: 12),
                SizedBox(
                  width: 400,
                  child: servers.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('لا توجد سيرفرات متاحة حالياً 🔒',
                              style: TextStyle(color: Colors.white54), textAlign: TextAlign.center),
                        )
                      : Column(
                          children: servers.asMap().entries.map((entry) {
                            final i = entry.key;
                            final s = entry.value;
                            return _ServerButton(
                              name: s['name'] ?? 'سيرفر ${i + 1}',
                              onTap: () {
                                Navigator.pop(context);
                                Get.to(
                                  () => LiveShowDetailsScreen(),
                                  arguments: ChannelModel(
                                    id: 0,
                                    name: '${match['team_1_name']} vs ${match['team_2_name']}',
                                    serverUrl: s['url'] ?? '',
                                    streamType: (s['url']?.toString().contains('mpd') ?? false) ? 'dash' : 'hls',
                                    requiredPlanLevel: 0,
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إغلاق', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Focused Match Card ────────────────────────────────────────────────────────
class _MatchFocusCard extends StatefulWidget {
  final Map<String, dynamic> match;
  final VoidCallback onTap;
  const _MatchFocusCard({required this.match, required this.onTap});

  @override
  State<_MatchFocusCard> createState() => _MatchFocusCardState();
}

class _MatchFocusCardState extends State<_MatchFocusCard> {
  bool isFocused = false;
  final FocusNode _fn = FocusNode();

  @override
  void dispose() {
    _fn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    final isLive = m['status'] == 'جارية الآن';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: InkWell(
        focusNode: _fn,
        onFocusChange: (f) => setState(() => isFocused = f),
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isFocused ? const Color(0xFF2D2B6B) : const Color(0xFF141420),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isFocused ? const Color(0xFF4C46E8) : Colors.white.withOpacity(0.08),
              width: isFocused ? 1.5 : 1,
            ),
            boxShadow: isFocused
                ? [BoxShadow(color: const Color(0xFF4C46E8).withOpacity(0.3), blurRadius: 14, spreadRadius: 1)]
                : [],
          ),
          child: Row(
            children: [
              // Date
              SizedBox(
                width: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m['date'] ?? '',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    if (isLive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('LIVE', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    else
                      Text(
                        'لم تبدأ',
                        style: const TextStyle(color: Colors.white30, fontSize: 10),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Team 1
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        m['team_1_name'] ?? '',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.right,
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _teamLogoSmall(m['team_1_logo'] ?? ''),
                  ],
                ),
              ),

              // Time / Score
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isLive ? Colors.red.withOpacity(0.15) : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isLive ? Colors.red.withOpacity(0.4) : Colors.white10),
                  ),
                  child: Text(
                    m['status'] ?? '',
                    style: TextStyle(
                      color: isLive ? Colors.redAccent : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Team 2
              Expanded(
                child: Row(
                  children: [
                    _teamLogoSmall(m['team_2_logo'] ?? ''),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        m['team_2_name'] ?? '',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),

              // League icon
              const SizedBox(width: 8),
              const Icon(Icons.sports_soccer, color: Colors.white30, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamLogoSmall(String url) {
    if (url.isEmpty) return const Icon(Icons.sports_soccer, color: Colors.white30, size: 30);
    return CachedNetworkImage(
      imageUrl: url,
      height: 30,
      width: 30,
      fit: BoxFit.contain,
      errorWidget: (_, __, ___) => const Icon(Icons.sports_soccer, color: Colors.white30, size: 30),
    );
  }
}

// ─── Server Button ─────────────────────────────────────────────────────────────
class _ServerButton extends StatefulWidget {
  final String name;
  final VoidCallback onTap;
  const _ServerButton({required this.name, required this.onTap});

  @override
  State<_ServerButton> createState() => _ServerButtonState();
}

class _ServerButtonState extends State<_ServerButton> {
  bool _focused = false;
  final FocusNode _fn = FocusNode();

  @override
  void dispose() {
    _fn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Focus(
        focusNode: _fn,
        onFocusChange: (f) => setState(() => _focused = f),
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter)) {
            widget.onTap();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: InkWell(
          onTap: widget.onTap,
          child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: _focused ? const Color(0xFF4C46E8) : Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _focused ? const Color(0xFF4C46E8) : Colors.white12),
          ),
          child: Row(
            children: [
              const Icon(Icons.play_circle_outline, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Text(
                widget.name,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, color: Colors.white54, size: 18),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
