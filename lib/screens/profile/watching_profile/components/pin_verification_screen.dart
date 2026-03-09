import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/components/otp_textfield_tv.dart';
import 'package:streamit_laravel/main.dart';
import 'package:streamit_laravel/screens/profile/watching_profile/watching_profile_controller.dart';
import 'package:streamit_laravel/utils/colors.dart';
import 'package:streamit_laravel/utils/common_base.dart';

import '../../../../components/app_scaffold.dart';

class PinVerificationScreen extends StatelessWidget {
  final String correctPin;
  final Function() onSuccess;

  PinVerificationScreen({
    super.key,
    required this.correctPin,
    required this.onSuccess,
  });

  final WatchingProfileController controller =
      Get.find<WatchingProfileController>();

  @override
  Widget build(BuildContext context) {
    return AppScaffoldNew(
      appBartitleText: locale.value.oTPVerification,
      topBarBgColor: scaffoldDarkColor,
      hideAppBar: true,
      body: Container(
        decoration: boxDecorationDefault(color: canvasColor),
        padding: EdgeInsets.all(16),
        child: FocusTraversalGroup(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(locale.value.parentalLock, style: boldTextStyle(size: 20)),
              Text(locale.value.enterPin, style: primaryTextStyle()),
              SizedBox(height: 16),
              SizedBox(
                height: 40,
                child: Focus(
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent) {
                      if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
                          event.logicalKey == LogicalKeyboardKey.arrowRight) {
                        FocusScope.of(context).nextFocus();
                        return KeyEventResult.handled;
                      }
                      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                        FocusScope.of(context).previousFocus();
                        return KeyEventResult.handled;
                      }
                      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                        controller.focusOTPField();
                        return KeyEventResult.handled;
                      }
                      if (event.logicalKey == LogicalKeyboardKey.enter ||
                          event.logicalKey == LogicalKeyboardKey.select) {
                        if (controller.pinController.text.length == 4) {
                          controller.btnFocus.requestFocus();
                          return KeyEventResult.handled;
                        }
                      }
                    }
                    return KeyEventResult.ignored;
                  },
                  child: GestureDetector(
                    onTap: controller.focusOTPField,
                    child: OTPTextFieldTV(
                      pinLength: 4,
                      fieldWidth: 38,
                      lastFocusNode: controller.lastActiveOTPFocusNode.value,
                      cursorColor: appColorPrimary,
                      textStyle: primaryTextStyle(),
                      decoration: InputDecoration(
                        counter: Offstage(),
                        contentPadding: EdgeInsets.only(bottom: 8, left: 2),
                        fillColor: cardDarkColor,
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: appColorPrimary),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: white),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      boxDecoration: BoxDecoration(
                        color: cardDarkColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (code) {
                        controller.pinController.text = code;
                      },
                      onCompleted: (code) {
                        controller.pinController.text = code;
                        hideKeyboard(context);
                        controller.btnFocus.requestFocus();
                      },
                      manageLastFocusMode: (focusNode) {
                        controller.lastActiveOTPFocusNode(focusNode);
                      },
                      onListMake: (list) {
                        controller.list = list;
                      },
                    ),
                  ),
                ),
              ),
              24.height,
              Row(
                children: [
                  const Spacer(),
                  Focus(
                    focusNode: controller.cancelBtnFocus,
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent) {
                        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                          controller.btnFocus.requestFocus();
                          return KeyEventResult.handled;
                        }
                        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                          controller.focusOTPField();
                          return KeyEventResult.handled;
                        }
                        if (event.logicalKey == LogicalKeyboardKey.enter ||
                            event.logicalKey == LogicalKeyboardKey.select) {
                          Get.back();
                          return KeyEventResult.handled;
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                    child: Builder(
                      builder: (context) {
                        final isFocused = Focus.of(context).hasFocus;
                        return AppButton(
                          text: locale.value.cancel,
                          onTap: () => Get.back(),
                          color: isFocused ? appColorPrimary : lightBtnColor,
                          textStyle: appButtonTextStyleWhite,
                          shapeBorder: RoundedRectangleBorder(
                            borderRadius: radius(6),
                            side: isFocused
                                ? const BorderSide(
                                    color: white,
                                    width: 3,
                                    strokeAlign: BorderSide.strokeAlignOutside)
                                : BorderSide.none,
                          ),
                        );
                      },
                    ),
                  ).expand(),
                  16.width,
                  Focus(
                    focusNode: controller.btnFocus,
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent) {
                        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                          controller.cancelBtnFocus.requestFocus();
                          return KeyEventResult.handled;
                        }
                        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                          controller.focusOTPField();
                          return KeyEventResult.handled;
                        }
                        if (event.logicalKey == LogicalKeyboardKey.enter ||
                            event.logicalKey == LogicalKeyboardKey.select) {
                          controller.verifyPin(correctPin, onSuccess, context: context);
                          return KeyEventResult.handled;
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                    child: Builder(
                      builder: (context) {
                        final isFocused = Focus.of(context).hasFocus;
                        return AppButton(
                          text: locale.value.verify,
                          onTap: () =>
                              controller.verifyPin(correctPin, onSuccess, context: context),
                          color: isFocused ? appColorPrimary : lightBtnColor,
                          textStyle: appButtonTextStyleWhite,
                          shapeBorder: RoundedRectangleBorder(
                            borderRadius: radius(6),
                            side: isFocused
                                ? const BorderSide(
                                    color: white,
                                    width: 3,
                                    strokeAlign: BorderSide.strokeAlignOutside)
                                : BorderSide.none,
                          ),
                        );
                      },
                    ),
                  ).expand(),
                  const Spacer(),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
