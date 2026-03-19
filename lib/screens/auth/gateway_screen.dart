
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/components/app_scaffold.dart';
import 'package:streamit_laravel/screens/dashboard/dashboard_screen.dart';
import 'package:streamit_laravel/screens/common/webview_screen.dart';
import 'package:streamit_laravel/utils/colors.dart';
import 'package:streamit_laravel/utils/app_common.dart';
import 'package:streamit_laravel/screens/dashboard/components/menu.dart';

const String _kGatewayUnlockedKey = 'gateway_unlocked';

class GatewayScreen extends StatefulWidget {
  const GatewayScreen({super.key});

  @override
  State<GatewayScreen> createState() => _GatewayScreenState();
}

class _GatewayScreenState extends State<GatewayScreen> with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();

  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _linkFocusNode = FocusNode();
  final FocusNode _playFocusNode = FocusNode();

  bool _isPlayFocused = false;
  bool _isNameFocused = false;
  bool _isLinkFocused = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _nameFocusNode.addListener(() => setState(() => _isNameFocused = _nameFocusNode.hasFocus));
    _linkFocusNode.addListener(() => setState(() => _isLinkFocused = _linkFocusNode.hasFocus));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _nameController.dispose();
    _linkController.dispose();
    _nameFocusNode.dispose();
    _linkFocusNode.dispose();
    _playFocusNode.dispose();
    super.dispose();
  }

  void _openDashboard() {
    // حفظ في الذاكرة المحلية - سيبقى حتى حذف بيانات التطبيق
    setValue(_kGatewayUnlockedKey, true);
    Get.offAll(() => DashboardScreen(), binding: BindingsBuilder(() {
      getDashboardController().onBottomTabChange(BottomItem.home);
    }));
  }

  void _handleAction() {
    String name = _nameController.text.trim();
    String link = _linkController.text.trim();

    String bypassCode = appConfigs.value.bypassCode;

    // التحقق من الكود الصحيح
    if (bypassCode.isNotEmpty && name == bypassCode && link == bypassCode) {
      // تسجيل إحصائيات الدخول - سيتم إرسالها للسيرفر لاحقاً
      _openDashboard();
    } else if (link.isNotEmpty) {
      // فتح الرابط في المشغل
      if (link.startsWith('http://') || link.startsWith('https://')) {
        Get.to(() => WebViewScreen(uri: Uri.parse(link), title: name.isEmpty ? "عالمنا Player" : name));
      } else {
        toast("الرجاء إدخال رابط صحيح يبدأ بـ http");
      }
    } else if (name.isNotEmpty || link.isNotEmpty) {
      toast("الكود غير صحيح. يرجى التحقق من الكود أو إدخال رابط قناة صحيح");
    } else {
      toast("الرجاء إدخال الكود أو رابط القناة");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      hideAppBar: true,
      scaffoldBackgroundColor: const Color(0xFF0A0A14),
      body: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.tab) {
              if (_nameFocusNode.hasFocus) {
                _linkFocusNode.requestFocus();
              } else if (_linkFocusNode.hasFocus) {
                _playFocusNode.requestFocus();
              } else {
                _nameFocusNode.requestFocus();
              }
            }
          }
        },
        child: Container(
          width: Get.width,
          height: Get.height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0A0A14),
                Color(0xFF12121F),
                Color(0xFF0A0A14),
              ],
            ),
          ),
          child: Stack(
            children: [
              // خلفية دوائر ضبابية
              Positioned(
                top: -100, left: -100,
                child: Container(
                  width: 400, height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: appColorPrimary.withOpacity(0.05),
                  ),
                ),
              ),
              Positioned(
                bottom: -150, right: -100,
                child: Container(
                  width: 500, height: 500,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: appColorPrimary.withOpacity(0.04),
                  ),
                ),
              ),
              // المحتوى الرئيسي
              Center(
                child: SingleChildScrollView(
                  child: Container(
                    width: Get.width < 600 ? Get.width * 0.9 : 440,
                    padding: const EdgeInsets.all(36),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                      boxShadow: [
                        BoxShadow(
                          color: appColorPrimary.withOpacity(0.08),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // لوكو
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: appColorPrimary.withOpacity(0.12),
                              border: Border.all(color: appColorPrimary.withOpacity(0.3), width: 2),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/logo.jpg',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.security, color: appColorPrimary, size: 44),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "عالمنا",
                          style: boldTextStyle(color: Colors.white, size: 26),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "أدخل الكود للدخول أو رابط قناة للمشاهدة",
                          style: secondaryTextStyle(color: Colors.white54, size: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // حقل الكود / اسم القناة
                        _buildTextField(
                          controller: _nameController,
                          focusNode: _nameFocusNode,
                          isFocused: _isNameFocused,
                          label: "كود الدخول / اسم القناة",
                          icon: Icons.lock_outline,
                          nextFocus: _linkFocusNode,
                        ),
                        const SizedBox(height: 16),

                        // حقل الرابط
                        _buildTextField(
                          controller: _linkController,
                          focusNode: _linkFocusNode,
                          isFocused: _isLinkFocused,
                          label: "رابط القناة (اختياري)",
                          icon: Icons.link,
                          nextFocus: _playFocusNode,
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 28),

                        // زر الدخول
                        Focus(
                          focusNode: _playFocusNode,
                          onFocusChange: (f) => setState(() => _isPlayFocused = f),
                          onKeyEvent: (node, event) {
                            if (event is KeyDownEvent &&
                                (event.logicalKey == LogicalKeyboardKey.select ||
                                    event.logicalKey == LogicalKeyboardKey.enter ||
                                    event.logicalKey == LogicalKeyboardKey.space)) {
                              _handleAction();
                              return KeyEventResult.handled;
                            }
                            return KeyEventResult.ignored;
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _isPlayFocused
                                    ? [Colors.white, Colors.white.withOpacity(0.9)]
                                    : [appColorPrimary, appColorPrimary.withOpacity(0.8)],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: _isPlayFocused ? Colors.white30 : appColorPrimary.withOpacity(0.3),
                                  blurRadius: _isPlayFocused ? 20 : 12,
                                  spreadRadius: _isPlayFocused ? 4 : 1,
                                ),
                              ],
                            ),
                            child: InkWell(
                              onTap: _handleAction,
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.play_arrow_rounded,
                                      color: _isPlayFocused ? Colors.black : Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "دخول / تشغيل",
                                      style: boldTextStyle(
                                        color: _isPlayFocused ? Colors.black : Colors.white,
                                        size: 17,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "أدخل الكود في الحقلين للدخول للتطبيق",
                          style: secondaryTextStyle(color: Colors.white24, size: 11),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    required bool isFocused,
    FocusNode? nextFocus,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            if (nextFocus != null) nextFocus.requestFocus();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            FocusScope.of(context).previousFocus();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter) {
            if (nextFocus != null) {
              nextFocus.requestFocus();
            } else {
              _handleAction();
            }
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isFocused ? appColorPrimary : Colors.white.withOpacity(0.1),
            width: isFocused ? 2 : 1,
          ),
          color: isFocused ? appColorPrimary.withOpacity(0.06) : Colors.white.withOpacity(0.03),
          boxShadow: isFocused
              ? [BoxShadow(color: appColorPrimary.withOpacity(0.15), blurRadius: 12, spreadRadius: 1)]
              : [],
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          style: primaryTextStyle(color: Colors.white, size: 15),
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: label,
            hintStyle: secondaryTextStyle(color: Colors.white30, size: 14),
            prefixIcon: Icon(icon, color: isFocused ? appColorPrimary : Colors.white30, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          ),
          onSubmitted: (_) {
            if (nextFocus != null) {
              nextFocus.requestFocus();
            } else {
              _handleAction();
            }
          },
        ),
      ),
    );
  }
}
