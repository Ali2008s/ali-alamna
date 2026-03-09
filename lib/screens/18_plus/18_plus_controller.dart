// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/main.dart';
import 'package:streamit_laravel/screens/dashboard/components/menu.dart';
import 'package:streamit_laravel/screens/dashboard/dashboard_screen.dart';
import 'package:streamit_laravel/utils/app_common.dart';
import 'package:streamit_laravel/utils/constants.dart';

class EighteenPlusController extends GetxController {
  /// Default to true (checked by default)
  RxBool is18Plus = true.obs;

  /// Focused states
  RxBool isCheckBoxFocused = false.obs;
  RxBool isYesBtnFocused = false.obs;
  RxBool isNoBtnFocused = false.obs;

  /// Focus nodes
  FocusNode checkBoxFNode = FocusNode();
  FocusNode yesBtnFNode = FocusNode();
  FocusNode noBtnFNode = FocusNode();

  /// Checkbox focus change handler
  void onCheckBoxFocusChange(bool value) {
    isCheckBoxFocused(value);
  }

  /// Yes button focus change handler
  void onYesBtnFocusChange(bool value) {
    isYesBtnFocused(value);
    log("isYesBtnFocused: $value");
  }

  /// No button focus change handler
  void onNoBtnFocusChange(bool value) {
    isNoBtnFocused(value);
    log("isNoBtnFocused: $value");
  }

  /// Checkbox key event handler
  KeyEventResult onCheckBoxKeyEvent(FocusNode node, KeyEvent event) {
    try {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
          toggleCheckBox();
          return KeyEventResult.handled;
        }
      }
    } catch (e) {
      log('error in checkbox KeyboardListener: $e');
    }
    return KeyEventResult.ignored;
  }

  /// Yes button key event handler
  KeyEventResult onYesBtnKeyEvent(FocusNode node, KeyEvent event) {
    try {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
          yesBtnClick();
          return KeyEventResult.handled;
        }
      }
    } catch (e) {
      log('error in isYesBtnFocused KeyboardListener: $e');
    }
    return KeyEventResult.ignored;
  }

  /// No button key event handler
  KeyEventResult onNoBtnKeyEvent(FocusNode node, KeyEvent event) {
    try {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
          noBtnClick();
          return KeyEventResult.handled;
        }
      }
    } catch (e) {
      log('error in isNoBtnFocused KeyboardListener: $e');
    }
    return KeyEventResult.ignored;
  }

  /// Toggle checkbox and move focus to Yes button if checked
  void toggleCheckBox() {
    is18Plus.value = !is18Plus.value;
    if (is18Plus.value) {
      Future.delayed(Duration(milliseconds: 100), () {
        yesBtnFNode.requestFocus();
      });
    }
  }

  /// Handle Yes button click
  Future<void> yesBtnClick() async {
    if (is18Plus.isTrue) {
      await setValue(SharedPreferenceConst.IS_FIRST_TIME_18, true);
      await setValue(SharedPreferenceConst.IS_18_PLUS, true);
      is18Plus(true);
      Get.offAll(
        () => DashboardScreen(),
        binding: BindingsBuilder(
          () {
            getDashboardController().onBottomTabChange(BottomItem.home);
          },
        ),
      );
    } else {
      toast(locale.value.pleaseConfirmContent);
    }
  }

  /// Handle No button click
  Future<void> noBtnClick() async {
    await setValue(SharedPreferenceConst.IS_FIRST_TIME_18, true);
    await setValue(SharedPreferenceConst.IS_18_PLUS, false);
    is18Plus(false);
    Get.offAll(
      () => DashboardScreen(),
      binding: BindingsBuilder(
        () {
          getDashboardController().onBottomTabChange(BottomItem.home);
        },
      ),
    );
  }

  @override
  void onClose() {
    checkBoxFNode.dispose();
    yesBtnFNode.dispose();
    noBtnFNode.dispose();
    super.onClose();
  }
}
