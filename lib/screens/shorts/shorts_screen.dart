import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pod_player/pod_player.dart';
import '../../components/app_scaffold.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:get/get.dart';
import 'package:streamit_laravel/screens/dashboard/dashboard_controller.dart';
import 'shorts_controller.dart';

// ─── Focus state enum for side panel navigation ───────────────────────────────
enum _SidePanel { none, like, comment }

class ShortsScreen extends StatelessWidget {
  const ShortsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ShortsScreenController controller = Get.put(ShortsScreenController());
    final FocusNode pageFocusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      pageFocusNode.requestFocus();
    });

    return AppScaffoldNew(
      hasLeadingWidget: false,
      hideAppBar: true,
      scaffoldBackgroundColor: Colors.black,
      body: Focus(
        focusNode: pageFocusNode,
        // Page-level: only LEFT arrow handled here (go to nav bar)
        // DOWN/UP are delegated to each ShortVideoPlayer
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              try {
                final dashCont = Get.find<DashboardController>();
                dashCont.bottomNavItems[dashCont.selectedBottomNavIndex.value]
                    .focusNode
                    .requestFocus();
                return KeyEventResult.handled;
              } catch (e) {
                log('Shorts nav error: $e');
              }
            }
          }
          return KeyEventResult.ignored;
        },
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                      color: Color(0xFFFF0050), strokeWidth: 2),
                  SizedBox(height: 16),
                  Text('جاري التحميل...',
                      style:
                          TextStyle(color: Colors.white60, fontSize: 14)),
                ],
              ),
            );
          }
          if (controller.shortsList.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.video_library_outlined,
                      color: Colors.white24, size: 80),
                  const SizedBox(height: 16),
                  const Text('لا توجد مقاطع بعد',
                      style:
                          TextStyle(color: Colors.white60, fontSize: 16)),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: controller.loadShorts,
                    icon: const Icon(Icons.refresh_rounded,
                        color: Color(0xFFFF0050)),
                    label: const Text('تحديث',
                        style: TextStyle(color: Color(0xFFFF0050))),
                  ),
                ],
              ),
            );
          }
          return PageView.builder(
            controller: controller.pageController,
            scrollDirection: Axis.vertical,
            physics: const NeverScrollableScrollPhysics(), // controlled via keys
            onPageChanged: controller.onPageChanged,
            itemCount: controller.shortsList.length,
            itemBuilder: (context, index) {
              return ShortVideoPlayer(
                key: ValueKey(index),
                data: controller.shortsList[index],
                index: index,
                isFocused: controller.currentIndex.value == index,
              );
            },
          );
        }),
      ),
    );
  }
}

// ─── Short Video Player ────────────────────────────────────────────────────────
class ShortVideoPlayer extends StatefulWidget {
  final Map<String, dynamic> data;
  final int index;
  final bool isFocused;

  const ShortVideoPlayer({
    super.key,
    required this.data,
    required this.index,
    this.isFocused = false,
  });

  @override
  State<ShortVideoPlayer> createState() => _ShortVideoPlayerState();
}

class _ShortVideoPlayerState extends State<ShortVideoPlayer>
    with TickerProviderStateMixin {
  // ─ Focus tracking ──────────────────────────────────────────────────────────
  _SidePanel _activePanel = _SidePanel.none;
  bool isLiked = false;

  final FocusNode _likeFocusNode = FocusNode();
  final FocusNode _commentFocusNode = FocusNode();

  // ─ Animations ──────────────────────────────────────────────────────────────
  late AnimationController _likeAnimCtrl;
  late Animation<double> _likeScaleAnim;
  late AnimationController _heartCtrl;
  late Animation<double> _heartAnim;
  bool _showHeartBurst = false;

  @override
  void initState() {
    super.initState();
    _likeAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _likeScaleAnim = Tween<double>(begin: 1.0, end: 1.45).animate(
        CurvedAnimation(parent: _likeAnimCtrl, curve: Curves.elasticOut));

    _heartCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _heartAnim =
        CurvedAnimation(parent: _heartCtrl, curve: Curves.easeOutCubic);

    _likeFocusNode.addListener(() {
      setState(() =>
          _activePanel = _likeFocusNode.hasFocus ? _SidePanel.like : _activePanel);
    });
    _commentFocusNode.addListener(() {
      setState(() => _activePanel =
          _commentFocusNode.hasFocus ? _SidePanel.comment : _activePanel);
    });
  }

  @override
  void dispose() {
    _likeFocusNode.dispose();
    _commentFocusNode.dispose();
    _likeAnimCtrl.dispose();
    _heartCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────
  void _handleLike() {
    setState(() {
      isLiked = !isLiked;
      _showHeartBurst = isLiked;
    });
    _likeAnimCtrl.forward().then((_) => _likeAnimCtrl.reverse());
    if (isLiked) {
      _heartCtrl.forward(from: 0).then((_) {
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted) setState(() => _showHeartBurst = false);
        });
      });
    }
    toast(isLiked ? '❤️ تم الإعجاب' : 'تم إلغاء الإعجاب');
  }

  void _exitSidePanel() {
    setState(() => _activePanel = _SidePanel.none);
    // Return focus to the page so UP/DOWN scroll again
    FocusScope.of(context).unfocus();
  }

  ShortsScreenController get _shortsCont =>
      Get.find<ShortsScreenController>();

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  int get _likes {
    final raw = widget.data['likes'] ?? 0;
    return raw is int ? raw : int.tryParse(raw.toString()) ?? 0;
  }

  int get _comments {
    final raw = widget.data['comments'] ?? 0;
    return raw is int ? raw : int.tryParse(raw.toString()) ?? 0;
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final String accountName =
        widget.data['account_name']?.toString() ?? 'عالمنا';
    final String title = widget.data['title']?.toString() ?? '';

    return Obx(() {
      final controller = _shortsCont.controllers[widget.index];

      // ─── Loading state ──────────────────────────────────────────────────
      if (controller == null || !controller.isInitialised) {
        return _buildLoading();
      }

      final double ar = controller.videoPlayerValue?.aspectRatio ?? 9 / 16;

      return KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is! KeyDownEvent) return;

          // ── Side panel is active: handle UP / DOWN inside panel ─────────
          if (_activePanel == _SidePanel.like) {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              // Move to comment
              _commentFocusNode.requestFocus();
              setState(() => _activePanel = _SidePanel.comment);
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              // Exit panel upward → go to previous short
              _exitSidePanel();
              _shortsCont.previousShort();
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _exitSidePanel();
            } else if (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter) {
              _handleLike();
            }
          } else if (_activePanel == _SidePanel.comment) {
            if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              _likeFocusNode.requestFocus();
              setState(() => _activePanel = _SidePanel.like);
            } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              // Exit panel downward → go to next short
              _exitSidePanel();
              _shortsCont.nextShort();
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _exitSidePanel();
            } else if (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter) {
              toast('التعليقات');
            }
          } else {
            // ── No panel active: UP/DOWN scroll, RIGHT enters panel ──────
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              // First go into side panel (like)
              _likeFocusNode.requestFocus();
              setState(() => _activePanel = _SidePanel.like);
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              _shortsCont.previousShort();
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _likeFocusNode.requestFocus();
              setState(() => _activePanel = _SidePanel.like);
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              try {
                final dashCont = Get.find<DashboardController>();
                dashCont
                    .bottomNavItems[dashCont.selectedBottomNavIndex.value]
                    .focusNode
                    .requestFocus();
              } catch (_) {}
            }
          }
        },
        child: Stack(
          children: [
            // ── Video ─────────────────────────────────────────────────────
            Positioned.fill(
              child: GestureDetector(
                onDoubleTap: _handleLike,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: ar,
                    child: PodVideoPlayer(
                      controller: controller,
                      alwaysShowProgressBar: false,
                      matchVideoAspectRatioToFrame: true,
                    ),
                  ),
                ),
              ),
            ),

            // ── Bottom gradient ───────────────────────────────────────────
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.25),
                        Colors.black.withValues(alpha: 0.72),
                        Colors.black.withValues(alpha: 0.93),
                      ],
                      stops: const [0.0, 0.42, 0.62, 0.83, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // ── Top bar ───────────────────────────────────────────────────
            _buildTopBar(),

            // ── Right side buttons ────────────────────────────────────────
            _buildSidePanel(),

            // ── Bottom info ───────────────────────────────────────────────
            _buildBottomInfo(accountName, title),

            // ── Heart burst ───────────────────────────────────────────────
            if (_showHeartBurst) _buildHeartBurst(),

            // ── Index pill ────────────────────────────────────────────────
            _buildIndexPill(),
          ],
        ),
      );
    });
  }

  // ─── Sub-widgets ───────────────────────────────────────────────────────────

  Widget _buildLoading() => Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  color: Color(0xFFFF0050),
                  strokeWidth: 2.5,
                ),
              ),
              const SizedBox(height: 14),
              Text('جاري التحميل...',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13)),
            ],
          ),
        ),
      );

  Widget _buildTopBar() => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 52, 16, 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.55),
                Colors.transparent
              ],
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_circle_outline_rounded,
                  color: Colors.white54, size: 16),
              SizedBox(width: 7),
              Text(
                'عالمنا',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildSidePanel() => Positioned(
        right: 10,
        bottom: 110,
        child: Column(
          children: [
            // Profile avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF0050), Color(0xFFD6174A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.person_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(height: 22),

            // ── Like button ─────────────────────────────────────────────
            Focus(
              focusNode: _likeFocusNode,
              child: GestureDetector(
                onTap: _handleLike,
                child: AnimatedBuilder(
                  animation: _likeScaleAnim,
                  builder: (_, child) =>
                      Transform.scale(scale: _likeScaleAnim.value, child: child),
                  child: _SidePanelButton(
                    icon: isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    label: _fmt(_likes + (isLiked ? 1 : 0)),
                    isActive: isLiked,
                    isFocused: _activePanel == _SidePanel.like,
                    activeColor: const Color(0xFFFF0050),
                    focusColor: const Color(0xFFFF0050),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),

            // ── Comment button ──────────────────────────────────────────
            Focus(
              focusNode: _commentFocusNode,
              child: GestureDetector(
                onTap: () => toast('التعليقات'),
                child: _SidePanelButton(
                  icon: Icons.mode_comment_rounded,
                  label: _fmt(_comments),
                  isActive: false,
                  isFocused: _activePanel == _SidePanel.comment,
                  activeColor: const Color(0xFF4FC3F7),
                  focusColor: const Color(0xFF4FC3F7),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildBottomInfo(String accountName, String title) => Positioned(
        left: 16,
        right: 75,
        bottom: 30,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account name row
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF0050), Color(0xFF9B1A30)],
                    ),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    '@$accountName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white54, width: 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'متابعة',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            if (title.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.45,
                  shadows: [Shadow(blurRadius: 5, color: Colors.black)],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            // Progress bar
            Obx(() => _buildProgressBar()),
          ],
        ),
      );

  Widget _buildProgressBar() {
    final total = _shortsCont.shortsList.length;
    final current = _shortsCont.currentIndex.value;
    final count = total.clamp(0, 12);
    return Row(
      children: List.generate(
        count,
        (i) => Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            height: 2.5,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: i == current
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeartBurst() => Positioned.fill(
        child: IgnorePointer(
          child: FadeTransition(
            opacity:
                Tween<double>(begin: 1.0, end: 0.0).animate(_heartAnim),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.4, end: 1.6).animate(_heartAnim),
              child: const Center(
                child: Icon(Icons.favorite_rounded,
                    color: Color(0xFFFF0050), size: 110),
              ),
            ),
          ),
        ),
      );

  Widget _buildIndexPill() => Positioned(
        right: 16,
        top: 56,
        child: Obx(
          () => Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_shortsCont.currentIndex.value + 1} / ${_shortsCont.shortsList.length}',
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ),
        ),
      );
}

// ─── Side Panel Button Widget ─────────────────────────────────────────────────
/// Displays icon + label with clear visual states:
///  • normal  : white icon, transparent bg
///  • focused : glowing border + light bg overlay + colored icon
///  • active  : fully colored icon (e.g. red heart when liked)
class _SidePanelButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;   // e.g. liked = true
  final bool isFocused;  // remote control focus
  final Color activeColor;
  final Color focusColor;

  const _SidePanelButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isFocused,
    required this.activeColor,
    required this.focusColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color iconColor = isActive
        ? activeColor
        : isFocused
            ? focusColor
            : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 58,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: isFocused
            ? focusColor.withValues(alpha: 0.18)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: isFocused
            ? Border.all(color: focusColor, width: 1.8)
            : Border.all(color: Colors.transparent, width: 1.8),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: focusColor.withValues(alpha: 0.45),
                  blurRadius: 14,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 34),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: isFocused ? focusColor : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              shadows: const [
                Shadow(blurRadius: 5, color: Colors.black87),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
