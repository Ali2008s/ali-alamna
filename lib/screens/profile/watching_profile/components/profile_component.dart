// profile_component.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/components/cached_image_widget.dart';
import 'package:streamit_laravel/services/focus_sound_service.dart';
import 'package:streamit_laravel/utils/app_common.dart';

import '../../../../main.dart';
import '../model/profile_watching_model.dart';
import '../watching_profile_controller.dart';

class ProfileComponent extends StatelessWidget {
  final WatchingProfileModel profile;
  final WatchingProfileController profileWatchingController;
  final double height;
  final double width;
  final EdgeInsets padding;
  final double imageSize;
  final FocusNode? focusNode;
  final Function()? onDownArrowKeyEvent;
  final Function()? onUpArrowKeyEvent;
  final Function()? onLeftArrowKeyEvent;
  final Function()? onRightArrowKeyEvent;
  final Function()? onSelectKeyEvent;
  final Function(bool)? onFocusChange;
  final RxBool? isFocused;

  const ProfileComponent({
    super.key,
    required this.profile,
    required this.profileWatchingController,
    required this.height,
    required this.width,
    required this.padding,
    required this.imageSize,
    this.focusNode,
    this.onDownArrowKeyEvent,
    this.onUpArrowKeyEvent,
    this.onLeftArrowKeyEvent,
    this.onRightArrowKeyEvent,
    this.onSelectKeyEvent,
    this.onFocusChange,
    this.isFocused,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => profileWatchingController.handleSelectProfile(profile, context),
      child: Focus(
        focusNode: focusNode,
        canRequestFocus: focusNode != null,
        autofocus: false,
        onKeyEvent: focusNode != null
            ? (node, event) {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    onDownArrowKeyEvent?.call();
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    onUpArrowKeyEvent?.call();
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                    onLeftArrowKeyEvent?.call();
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                    onRightArrowKeyEvent?.call();
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
                    onSelectKeyEvent?.call();
                    profileWatchingController.handleSelectProfile(profile, context);
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              }
            : null,
        onFocusChange: (value) {
          if (value) {
            FocusSoundService.play();
          }
          onFocusChange?.call(value);
        },
        child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isFocused != null ? focusBorder(isFocused!.value) : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: Get.width * 0.12,
                  width: Get.width * 0.12,
                  decoration: boxDecorationDefault(
                    borderRadius: radius(Get.width * 0.12 / 2),
                  ),
                  child: ClipOval(
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        CachedImageWidget(url: profile.avatar, width: Get.width * 0.12, height: Get.width * 0.12, fit: BoxFit.cover),
                        if (profile.isChildProfile == 1)
                          Positioned(
                            top: 0,
                            child: Container(width: Get.width * 0.12, height: Get.width * 0.12 * 0.72, color: Colors.white.withValues(alpha: 0.2)),
                          ),
                        if (profile.isChildProfile == 1)
                          Positioned(
                            bottom: 0,
                            child: Container(
                              width: Get.width * 0.12,
                              height: Get.width * 0.12 * 0.27,
                              color: Colors.red,
                              alignment: Alignment.center,
                              child: Text(locale.value.kids, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                10.height,
                Marquee(child: Text(profile.name.capitalizeEachWord(), textAlign: TextAlign.center, style: boldTextStyle())),
              ],
            ),
          ),
        ),
      );
  }
}
