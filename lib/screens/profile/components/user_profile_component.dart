import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/screens/profile/watching_profile/components/profile_component.dart';
import 'package:streamit_laravel/screens/profile/watching_profile/model/profile_watching_model.dart';
import 'package:streamit_laravel/screens/profile/watching_profile/watching_profile_controller.dart';

import '../../../services/focus_sound_service.dart';
import '../../../utils/app_common.dart';
import '../../../utils/colors.dart';
import 'user_profile_controller.dart';

class UserProfileComponent extends StatelessWidget {
  final FocusNode? firstProfileFocusNode;
  final Function()? onUpArrowKeyEvent;
  final Function()? onDownArrowKeyEvent;
  final Function()? onLeftArrowKeyEvent;
  final Function()? onRightArrowKeyEvent;

  const UserProfileComponent({super.key,this.onDownArrowKeyEvent, this.firstProfileFocusNode, this.onUpArrowKeyEvent, this.onLeftArrowKeyEvent, this.onRightArrowKeyEvent});

  @override
  Widget build(BuildContext context) {
    final UserProfileController userProfileCont = Get.put(UserProfileController());
    final WatchingProfileController profileWatchingController = Get.put(WatchingProfileController(navigateToDashboard: true));

    // Initialize first profile focus node during widget build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      userProfileCont.initializeWithFirstProfileFocusNode(firstProfileFocusNode);
    });

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(
            () => HorizontalList(
              spacing: 16,
              padding: EdgeInsets.only(left: 8),
              itemCount: accountProfiles.length,
              itemBuilder: (context, index) {
                List<WatchingProfileModel> sortedProfiles = List<WatchingProfileModel>.from(accountProfiles);
                sortedProfiles.sort((a, b) {
                  if (a.id == profileId.value) return -1;
                  if (b.id == profileId.value) return 1;
                  return 0;
                });
                WatchingProfileModel profile = sortedProfiles[index];
                final focusNode = index < userProfileCont.profileFocusNodes.length ? userProfileCont.profileFocusNodes[index] : null;

                // Get focus state from controller
                final isFocused = userProfileCont.getFocusState(index);

                return Focus(
                  focusNode: focusNode,
                  canRequestFocus: true,
                  autofocus: focusNode == null && index == 0,
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent) {
                      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                        onDownArrowKeyEvent?.call();
                        userProfileCont.onDownArrowKeyEvent();
                        return KeyEventResult.handled;
                      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                        onUpArrowKeyEvent?.call();
                        return KeyEventResult.handled;
                      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                        userProfileCont.onLeftArrowKeyEvent(index, onLeftArrowKeyEvent);
                        return KeyEventResult.handled;
                      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                        userProfileCont.onRightArrowKeyEvent(index, onRightArrowKeyEvent);
                        return KeyEventResult.handled;
                      } else if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
                        profileWatchingController.handleSelectProfile(profile, context);
                        return KeyEventResult.handled;
                      }
                    }
                    return KeyEventResult.ignored;
                  },
                  onFocusChange: (value) {
                    if (value) {
                      FocusSoundService.play();
                    }
                    userProfileCont.onProfileFocusChange(value, index);
                  },
                  child: Obx(
                    () => Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: focusBorder(isFocused.value),
                      ),
                      child: ProfileComponent(
                        focusNode: null,
                        // No focus handling in ProfileComponent
                        onDownArrowKeyEvent: () {
                          userProfileCont.onDownArrowKeyEvent();
                        },
                        onUpArrowKeyEvent: onUpArrowKeyEvent,
                        onLeftArrowKeyEvent: () {
                          userProfileCont.onLeftArrowKeyEvent(index, onLeftArrowKeyEvent);
                        },
                        onRightArrowKeyEvent: () {
                          userProfileCont.onRightArrowKeyEvent(index, onRightArrowKeyEvent);
                        },
                        onFocusChange: (hasFocus) {
                          // Focus is handled by parent Focus widget
                        },
                        profile: profile,
                        profileWatchingController: profileWatchingController,
                        height: 140,
                        width: Get.width / 2 - 62,
                        padding: EdgeInsets.zero,
                        imageSize: 50,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
