import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/generated/assets.dart';
import 'package:streamit_laravel/services/focus_sound_service.dart';
import 'package:streamit_laravel/utils/app_common.dart';

import '../../../../components/cached_image_widget.dart';
import '../../../../main.dart';
import '../../../../utils/colors.dart';
import '../sign_in_controller.dart';

class SocialAuthComponent extends StatelessWidget {
  const SocialAuthComponent({super.key, required this.signInController});

  final SignInController signInController;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 12,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Obx(
          () {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 16,
              children: [
                if(signInController.isLeftFormEmail.value ? appConfigs.value.isOtpLoginEnabled : true)
                SocialIconWidget(
                  signInController: signInController,
                  buttonWidth: Get.width * 0.25,
                  childPadding: EdgeInsets.symmetric(horizontal: 16),
                  focusNode: signInController.emailSignINFocusNode,
                  isFocused: signInController.isEmailSignInBtnFocused,
                  icon: signInController.isLeftFormEmail.value ? Assets.socialMediaPhone : Icons.email_outlined,
                  text:
                      signInController.isLeftFormEmail.value ? locale.value.loginWithOTP : locale.value.loginWithEmail,
                  iconColor: signInController.isLeftFormEmail.value ? whiteColor : null,
                  onTap: () {
                    signInController.toggleLeftFormType();
                  },
                ).expand(),
                if(appConfigs.value.isGoogleLoginEnabled)
                SocialIconWidget(
                  signInController: signInController,
                  buttonWidth: Get.width * 0.25,
                  childPadding: EdgeInsets.symmetric(horizontal: 16),
                  focusNode: signInController.gSignINFocusNode,
                  isFocused: signInController.isGoogleSignInBtnFocused,
                  icon: Assets.socialMediaGoogle,
                  text: locale.value.signInWithGoogle,
                  onTap: () {
                    signInController.googleSignIn();
                  },
                ).expand(),
              ],
            );
          },
        ),
      ],
    );
  }
}

class SocialIconWidget extends StatelessWidget {
  final dynamic icon; // Can be String or IconData
  final Function()? onTap;
  final Color? iconColor;
  final Size? iconSize;
  final double? buttonWidth;
  final String? text;
  final FocusNode focusNode;
  final EdgeInsets? childPadding;
  final RxBool isFocused;

  const SocialIconWidget({
    super.key,
    required this.icon,
    this.onTap,
    this.text,
    this.iconColor,
    this.iconSize,
    this.buttonWidth,
    required this.focusNode,
    this.childPadding,
    required this.isFocused,
    required this.signInController,
  });

    final SignInController signInController;
  @override
  Widget build(BuildContext context) {

    return Focus(
      focusNode: focusNode,
      canRequestFocus: true,
      skipTraversal: false,
      onFocusChange: (value) {
        if (value) {
          FocusSoundService.play();
        }
        isFocused(value);
        log('Social button focused ($text): $value');
      },
      onKeyEvent: (node, event) {
        try {
          if (event is KeyDownEvent) {
            // Handle UP arrow key
            if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              signInController.handleSocialButtonUpArrow();
              return KeyEventResult.handled;
            }

            // Handle DOWN arrow key - navigate to terms and conditions
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              signInController.termsConditionFocus.requestFocus();
              return KeyEventResult.handled;
            }

            // Handle LEFT/RIGHT arrow keys for navigation between social buttons
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              signInController.handleSocialButtonLeftArrow(focusNode);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              signInController.handleSocialButtonRightArrow(focusNode);
              return KeyEventResult.handled;
            }

            // Handle SELECT key
            if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
              onTap?.call();
              return KeyEventResult.handled;
            }
          }
        } catch (e) {
          log('error in Social button KeyboardListener: $e');
        }
        return KeyEventResult.ignored;
      },
      child: Obx(
        () => AppButton(
          onTap: onTap,
          splashColor: appColorPrimary.withValues(alpha: 0.3),
          shapeBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: isFocused.value
                ? BorderSide(color: white, width: 2, strokeAlign: BorderSide.strokeAlignOutside)
                : BorderSide.none,
          ),
          padding: childPadding ?? EdgeInsets.zero,
          color: backgroundColor.withValues(alpha: 0.8),
          height: 40,
          width: buttonWidth,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon is String)
                CachedImageWidget(
                  url: icon,
                  fit: BoxFit.cover,
                  height: iconSize?.height ?? 16,
                  width: iconSize?.width ?? 16,
                  color: iconColor,
                ).paddingRight(12)
              else if (icon is IconData)
                Icon(
                  icon,
                  size: iconSize?.height ?? 16,
                  color: iconColor ?? Colors.grey[600],
                ).paddingRight(12),
              Text(
                text.validate(),
                style: boldTextStyle(size: 13),
              )
            ],
          ),
        ),
      ),
    );
  }
}
