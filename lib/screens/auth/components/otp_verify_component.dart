import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:streamit_laravel/components/app_logo_widget.dart';
import 'package:streamit_laravel/components/loader_widget.dart';
import 'package:streamit_laravel/screens/auth/components/otp_verify_controller.dart';
import 'package:streamit_laravel/screens/auth/sign_in/sign_in_controller.dart';
import 'package:streamit_laravel/utils/app_common.dart';
import 'package:streamit_laravel/utils/colors.dart';
import 'package:streamit_laravel/utils/common_responsive_utilies.dart';
import 'package:streamit_laravel/utils/constants.dart';

import '../../../main.dart';

// ============================================================================
// OTP Verification Screen - UI Layer with Number Pad
// ============================================================================

// Responsive ratios based on 960 base width
class _OTPResponsiveRatios {
  static const baseWidth = 960.0;

  // Container & Layout
  static const containerMaxWidth = 600 / baseWidth;
  static const containerPaddingHorizontal = 32 / baseWidth;
  static const containerPaddingVertical = 0.03; // 3% of screen height

  // Spacing
  static const logoToHeaderSpacing = 0.02; // 2% of screen height
  static const headerToInstructionSpacing = 0.03; // 3% of screen height
  static const instructionToOTPSpacing = 0.04; // 4% of screen height
  static const otpToTimerSpacing = 0.03; // 3% of screen height
  static const timerToKeypadSpacing = 0.04; // 4% of screen height

  // Logo
  static const logoSize = 70 / baseWidth;

  // Instruction
  static const instructionFontSize = 12 / baseWidth;
  static const demoHintFontSize = 11 / baseWidth;

  // OTP Display
  static const otpBoxSize = 38 / baseWidth;
  static const otpBoxSpacing = 6 / baseWidth;
  static const otpBoxRadius = 8 / baseWidth;
  static const otpBoxBorderWidth = 2 / baseWidth;
  static const otpBoxBorderWidthActive = 2.5 / baseWidth;

  // Timer & Resend
  static const timerFontSize = 14 / baseWidth;
  static const resendFontSize = 12 / baseWidth;

  // Keypad
  static const keypadButtonSize = 50 / baseWidth;
  static const keypadButtonSpacing = 8 / baseWidth;
  static const keypadButtonFontSize = 24 / baseWidth;
  static const keypadButtonIconSize = 24 / baseWidth;
}

class OTPVerifyComponent extends StatelessWidget {
  final String mobileNo;

  OTPVerifyComponent({super.key, required this.mobileNo});

  final SignInController signInController = Get.find<SignInController>();

  @override
  Widget build(BuildContext context) {
    // Initialize controller with unique tag
    final controller = Get.put(
      OTPVerifyController(signInController: signInController),
      tag: DateTime.now().millisecondsSinceEpoch.toString(),
    );

    return Scaffold(
      body: Container(
        decoration: _buildGradientBackground(),
        child: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(child: _buildMainContent(context, controller)),
              Obx(
                () => signInController.isLoading.isTrue
                    ? const Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: LoaderWidget(),
                      )
                    : const Offstage(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // Key Event Handling for Keypad
  // ============================================================================
  KeyEventResult _handleKeypadKeyEvent(
    KeyEvent event,
    OTPVerifyController controller,
  ) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final keyHandlers = {
      LogicalKeyboardKey.arrowUp: controller.moveUp,
      LogicalKeyboardKey.arrowDown: controller.moveDown,
      LogicalKeyboardKey.arrowLeft: controller.moveLeft,
      LogicalKeyboardKey.arrowRight: controller.moveRight,
      LogicalKeyboardKey.enter: controller.handleSelect,
      LogicalKeyboardKey.select: controller.handleSelect,
      LogicalKeyboardKey.escape: controller.handleEscape,
      LogicalKeyboardKey.backspace: controller.handleBackspace,
    };

    final handler = keyHandlers[event.logicalKey];
    if (handler != null) {
      handler();
      return KeyEventResult.handled;
    }

    // Handle number keys directly
    if (event.logicalKey.keyLabel.length == 1) {
      final char = event.logicalKey.keyLabel;
      if (RegExp('[0-9]').hasMatch(char)) {
        controller.onNumberPressed(char);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  // ============================================================================
  // Background
  // ============================================================================
  BoxDecoration _buildGradientBackground() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A), Color(0xFF0A0A0A)],
        stops: [0.0, 0.5, 1.0],
      ),
    );
  }

  // ============================================================================
  // Main Content
  // ============================================================================
  Widget _buildMainContent(BuildContext context, OTPVerifyController controller) {
    return SingleChildScrollView(
      child: Container(
        width: CommonResponsiveUtilities.width(context, _OTPResponsiveRatios.containerMaxWidth),
        padding: EdgeInsets.symmetric(
          horizontal: CommonResponsiveUtilities.width(context, _OTPResponsiveRatios.containerPaddingHorizontal),
          vertical: CommonResponsiveUtilities.screenHeight(context) * _OTPResponsiveRatios.containerPaddingVertical,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLogo(context),
            SizedBox(
              height: CommonResponsiveUtilities.screenHeight(context) * _OTPResponsiveRatios.logoToHeaderSpacing,
            ),
            SizedBox(
              height: CommonResponsiveUtilities.screenHeight(context) * _OTPResponsiveRatios.headerToInstructionSpacing,
            ),
            _buildInstructionText(context),
            if (signInController.phoneCont.text == Constants.demoNumber) _buildDemoHint(context),
            SizedBox(
              height: CommonResponsiveUtilities.screenHeight(context) * _OTPResponsiveRatios.instructionToOTPSpacing,
            ),
            _buildOTPDisplay(context, controller),
            SizedBox(
              height: CommonResponsiveUtilities.screenHeight(context) * _OTPResponsiveRatios.otpToTimerSpacing,
            ),
            _buildTimerOrResend(context, controller),
            SizedBox(
              height: CommonResponsiveUtilities.screenHeight(context) * _OTPResponsiveRatios.timerToKeypadSpacing,
            ),
            _buildNumberPad(context, controller),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // Logo Section
  // ============================================================================
  Widget _buildLogo(BuildContext context) {
    return DynamicAppLogoWidget(
      size: Size(
        CommonResponsiveUtilities.width(context, _OTPResponsiveRatios.logoSize),
        CommonResponsiveUtilities.width(context, _OTPResponsiveRatios.logoSize),
      ),
      image: appConfigs.value.appLogo,
    );
  }

  // ============================================================================
  // Header Section
  // ============================================================================

  // ============================================================================
  // Instruction Text
  // ============================================================================
  Widget _buildInstructionText(BuildContext context) {
    return Text(
      locale.value.checkYourSmsInboxAndEnterTheCodeYouGet,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: CommonResponsiveUtilities.fontSize(context, _OTPResponsiveRatios.instructionFontSize),
        color: Colors.white.withValues(alpha: 0.7),
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
    );
  }

  // ============================================================================
  // Demo Hint
  // ============================================================================
  Widget _buildDemoHint(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: CommonResponsiveUtilities.screenHeight(context) * 0.02,
      ),
      child: Text(
        'Use this OTP - 123456',
        style: TextStyle(
          fontSize: CommonResponsiveUtilities.fontSize(context, _OTPResponsiveRatios.demoHintFontSize),
          color: appColorPrimary.withValues(alpha: 0.9),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ============================================================================
  // OTP Display
  // ============================================================================
  Widget _buildOTPDisplay(BuildContext context, OTPVerifyController controller) {
    return AnimatedBuilder(
      animation: controller.shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(controller.shakeAnimation.value, 0),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(6, (index) {
          return _buildOTPBox(context, index, controller);
        }),
      ),
    );
  }

  Widget _buildOTPBox(BuildContext context, int index, OTPVerifyController controller) {
    final boxSize = CommonResponsiveUtilities.width(context, _OTPResponsiveRatios.otpBoxSize);
    final spacing = CommonResponsiveUtilities.width(context, _OTPResponsiveRatios.otpBoxSpacing);

    return Obx(() {
      final hasValue = controller.hasOTPValue(index);
      final isActive = controller.isOTPBoxActive(index);
      final isError = controller.isError.value;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.symmetric(horizontal: spacing),
        width: boxSize,
        height: boxSize,
        decoration: BoxDecoration(
          color: isError ? Colors.red.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
          borderRadius: CommonResponsiveUtilities.radius(context, _OTPResponsiveRatios.otpBoxRadius),
          border: Border.all(
            color: isError
                ? Colors.red
                : isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.3),
            width: isActive ? CommonResponsiveUtilities.width(context, _OTPResponsiveRatios.otpBoxBorderWidthActive) : CommonResponsiveUtilities.width(context, _OTPResponsiveRatios.otpBoxBorderWidth),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: hasValue
                ? Container(
                    key: ValueKey('filled_$index'),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(color: isError ? Colors.red : Colors.white, shape: BoxShape.circle),
                  )
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),
        ),
      );
    });
  }

  // ============================================================================
  // Timer & Resend Section
  // ============================================================================
  Widget _buildTimerOrResend(BuildContext context, OTPVerifyController controller) {
    return Obx(() {
      if (signInController.codeResendTime.value != 0) {
        // Show timer
        return Text(
          locale.value.otpValidUntill(signInController.codeResendTime.value),
          style: TextStyle(
            fontSize: CommonResponsiveUtilities.fontSize(context, _OTPResponsiveRatios.timerFontSize),
            color: appColorPrimary,
            fontWeight: FontWeight.w500,
          ),
        );
      } else {
        // Show resend button with focus handling
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              locale.value.didntGetTheOTP,
              style: TextStyle(
                fontSize: CommonResponsiveUtilities.fontSize(context, _OTPResponsiveRatios.resendFontSize),
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(width: 8),
            Obx(() => Focus(
                  focusNode: controller.resendButtonFocusNode,
                  onFocusChange: (hasFocus) {
                    controller.isResendButtonFocused.value = hasFocus;
                  },
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent) {
                      // Down arrow - go back to keypad
                      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                        controller.moveBackToKeypad();
                        return KeyEventResult.handled;
                      }

                      // Select/Enter - trigger resend
                      if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
                        controller.handleResendOTP();
                        return KeyEventResult.handled;
                      }
                    }
                    return KeyEventResult.ignored;
                  },
                  child: GestureDetector(
                    onTap: controller.handleResendOTP,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: controller.isResendButtonFocused.value ? appColorPrimary.withValues(alpha: 0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: controller.isResendButtonFocused.value ? Colors.white : appColorPrimary,
                          width: controller.isResendButtonFocused.value ? 2.5 : 1.5,
                        ),
                        boxShadow: controller.isResendButtonFocused.value
                            ? [
                                BoxShadow(color: Colors.white.withValues(alpha: 0.3), blurRadius: 12, spreadRadius: 2),
                              ]
                            : null,
                      ),
                      child: Text(
                        locale.value.resendOTP,
                        style: TextStyle(
                          fontSize: CommonResponsiveUtilities.fontSize(
                            context,
                            _OTPResponsiveRatios.resendFontSize,
                          ),
                          color: controller.isResendButtonFocused.value ? Colors.white : appColorPrimary,
                          fontWeight: controller.isResendButtonFocused.value ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                )),
          ],
        );
      }
    });
  }

  // ============================================================================
  // Number Pad
  // ============================================================================
  Widget _buildNumberPad(BuildContext context, OTPVerifyController controller) {
    final buttonSize = CommonResponsiveUtilities.width(context, _OTPResponsiveRatios.keypadButtonSize);
    final spacing = CommonResponsiveUtilities.width(context, _OTPResponsiveRatios.keypadButtonSpacing);

    return Obx(() => Focus(
          autofocus: true,
          skipTraversal: !controller.isKeypadFocused.value,
          onKeyEvent: (node, event) => _handleKeypadKeyEvent(event, controller),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Rows 1-3 (numbers 1-9)
              ...List.generate(3, (row) {
                return Padding(
                  padding: EdgeInsets.only(bottom: spacing),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (col) {
                      final number = (row * 3 + col + 1).toString();
                      return Obx(() {
                        final isSelected = controller.isSelected(row, col);
                        return _buildNumberButton(context, number, isSelected, buttonSize, spacing, controller);
                      });
                    }),
                  ),
                );
              }),

              // Bottom row (clear, 0, backspace)
              Padding(
                padding: EdgeInsets.only(bottom: spacing),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Obx(() {
                      final isSelected = controller.isSelected(3, 0);
                      return _buildClearButton(context, isSelected, buttonSize, spacing, controller);
                    }),
                    Obx(() {
                      final isSelected = controller.isSelected(3, 1);
                      return _buildNumberButton(context, '0', isSelected, buttonSize, spacing, controller);
                    }),
                    Obx(() {
                      final isSelected = controller.isSelected(3, 2);
                      return _buildBackspaceButton(context, isSelected, buttonSize, spacing, controller);
                    }),
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildNumberButton(BuildContext context, String number, bool isSelected, double size, double spacing, OTPVerifyController controller) {
    return GestureDetector(
      onTap: () => controller.onNumberPressed(number),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: EdgeInsets.symmetric(horizontal: spacing / 2),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(color: Colors.white.withValues(alpha: 0.3), blurRadius: 16, spreadRadius: 2),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            number,
            style: TextStyle(
              fontSize: CommonResponsiveUtilities.fontSize(context, _OTPResponsiveRatios.keypadButtonFontSize),
              color: Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton(
    BuildContext context,
    bool isSelected,
    double size,
    double spacing,
    OTPVerifyController controller,
  ) {
    return GestureDetector(
      onTap: controller.handleBackspace,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: EdgeInsets.symmetric(horizontal: spacing / 2),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2), width: isSelected ? 2.5 : 1.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(color: Colors.white.withValues(alpha: 0.3), blurRadius: 16, spreadRadius: 2),
                ]
              : null,
        ),
        child: Center(
          child: Icon(
            Icons.backspace_outlined,
            color: Colors.white,
            size: CommonResponsiveUtilities.width(context, _OTPResponsiveRatios.keypadButtonIconSize),
          ),
        ),
      ),
    );
  }

  Widget _buildClearButton(BuildContext context, bool isSelected, double size, double spacing, OTPVerifyController controller) {
    return GestureDetector(
      onTap: controller.handleClear,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: EdgeInsets.symmetric(horizontal: spacing / 2),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2), width: isSelected ? 2.5 : 1.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(color: Colors.white.withValues(alpha: 0.3), blurRadius: 16, spreadRadius: 2),
                ]
              : null,
        ),
        child: Center(
          child: Icon(
            Icons.close,
            color: Colors.white,
            size: CommonResponsiveUtilities.width(context, _OTPResponsiveRatios.keypadButtonIconSize),
          ),
        ),
      ),
    );
  }
}
