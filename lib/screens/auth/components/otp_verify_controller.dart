import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/screens/auth/sign_in/sign_in_controller.dart';

// ============================================================================
// OTP Verification Controller - Business Logic
// ============================================================================

class OTPVerifyController extends GetxController with GetSingleTickerProviderStateMixin {
  // ============================================================================
  // Dependencies
  // ============================================================================
  final SignInController signInController;

  OTPVerifyController({required this.signInController});

  // ============================================================================
  // Observable State
  // ============================================================================
  final RxList<String> otpDigits = <String>['', '', '', '', '', ''].obs;
  final RxInt currentOTPIndex = 0.obs;
  final RxBool isError = false.obs;

  // Keyboard navigation
  final RxInt selectedRow = 0.obs;
  final RxInt selectedCol = 1.obs; // Start at number 2 (middle of first row)
  final RxBool isKeypadFocused = true.obs; // Track if keypad has focus

  // Focus nodes
  final FocusNode resendButtonFocusNode = FocusNode();
  final RxBool isResendButtonFocused = false.obs;

  // Animation
  late AnimationController shakeController;
  late Animation<double> shakeAnimation;

  // ============================================================================
  // Lifecycle
  // ============================================================================
  @override
  void onInit() {
    super.onInit();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void onClose() {
    shakeController.dispose();
    resendButtonFocusNode.dispose();
    super.onClose();
  }

  // ============================================================================
  // Navigation Methods
  // ============================================================================
  void moveUp() {
    if (selectedRow.value > 0) {
      selectedRow.value--;
    } else if (selectedRow.value == 0 && isResendButtonVisible) {
      // Move to resend button if visible (from top row: 1, 2, 3)
      isKeypadFocused.value = false;
      resendButtonFocusNode.requestFocus();
    }
  }

  void moveDown() {
    if (selectedRow.value < 3) {
      selectedRow.value++;
    }
  }

  void moveLeft() {
    if (selectedCol.value > 0) {
      selectedCol.value--;
    }
  }

  void moveRight() {
    if (selectedCol.value < 2) {
      selectedCol.value++;
    }
  }

  void handleSelect() {
    final value = getKeyValue(selectedRow.value, selectedCol.value);
    if (value != null) {
      if (value == 'backspace') {
        handleBackspace();
      } else if (value == 'clear') {
        handleClear();
      } else {
        onNumberPressed(value);
      }
    }
  }

  String? getKeyValue(int row, int col) {
    if (row == 3) {
      // Bottom row: clear, 0, backspace
      if (col == 0) return 'clear';
      if (col == 1) return '0';
      if (col == 2) return 'backspace';
    }

    // Rows 0-2: numbers 1-9
    return ((row * 3) + col + 1).toString();
  }

  // ============================================================================
  // OTP Logic
  // ============================================================================
  void onNumberPressed(String number) {
    if (currentOTPIndex.value < 6) {
      otpDigits[currentOTPIndex.value] = number;
      currentOTPIndex.value++;
      isError.value = false;

      // Update the SignInController's verifyCont
      signInController.verifyCont.text = otpDigits.join();
      signInController.getVerifyBtnEnable();

      // Auto-verify when all 6 digits are entered
      if (currentOTPIndex.value == 6) {
        Future.delayed(const Duration(milliseconds: 400), verifyOTP);
      }
    }
  }

  void handleBackspace() {
    if (currentOTPIndex.value > 0) {
      currentOTPIndex.value--;
      otpDigits[currentOTPIndex.value] = '';
      isError.value = false;

      // Update the SignInController's verifyCont
      signInController.verifyCont.text = otpDigits.join();
      signInController.getVerifyBtnEnable();
    }
  }

  void handleClear() {
    otpDigits.fillRange(0, 6, '');
    currentOTPIndex.value = 0;
    isError.value = false;

    // Update the SignInController's verifyCont
    signInController.verifyCont.clear();
    signInController.getVerifyBtnEnable();
  }

  void verifyOTP() {
    final enteredOTP = otpDigits.join();

    if (enteredOTP.length == 6 && signInController.isVerifyBtn.isTrue && signInController.codeResendTime.value != 0) {
      signInController.checkIfDemoUser(
        verify: true,
        callBack: () {
          signInController.onVerifyPressed();
        },
      );
    }
  }

  void showError({String? message}) {
    isError.value = true;

    shakeController.forward().then((_) {
      shakeController.reverse();
    });

    if (message != null) {
      toast(message);
    }

    Future.delayed(const Duration(milliseconds: 600), () {
      // Don't clear automatically - let user correct their mistake
      isError.value = false;
    });
  }

  void handleEscape() {
    Get.back();
  }

  // ============================================================================
  // Resend OTP Logic
  // ============================================================================
  void handleResendOTP() {
    if (signInController.codeResendTime.value == 0) {
      handleClear();
      signInController.reSendOTP();
    }
  }

  void moveBackToKeypad() {
    isKeypadFocused.value = true;
    isResendButtonFocused.value = false;
    // Reset to top row when coming back from resend button
    selectedRow.value = 0;
    selectedCol.value = 1; // Default to "2" button
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================
  bool isSelected(int row, int col) {
    return selectedRow.value == row && selectedCol.value == col;
  }

  bool isOTPBoxActive(int index) {
    return index == currentOTPIndex.value && !isError.value;
  }

  bool hasOTPValue(int index) {
    return otpDigits[index].isNotEmpty;
  }

  bool get isResendButtonVisible => signInController.codeResendTime.value == 0;

  bool get canVerify => signInController.isVerifyBtn.isTrue && signInController.codeResendTime.value != 0;
}
