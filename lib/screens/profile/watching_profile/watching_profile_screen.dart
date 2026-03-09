import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/components/app_logo_widget.dart';
import 'package:streamit_laravel/components/app_scaffold.dart';
import 'package:streamit_laravel/screens/profile/watching_profile/components/profile_component.dart';
import 'package:streamit_laravel/screens/profile/watching_profile/model/profile_watching_model.dart';
import 'package:streamit_laravel/screens/profile/watching_profile/watching_profile_controller.dart';
import 'package:streamit_laravel/services/focus_sound_service.dart';
import 'package:streamit_laravel/utils/app_common.dart';
import 'package:streamit_laravel/utils/colors.dart';
import 'package:streamit_laravel/utils/common_base.dart';
import 'package:streamit_laravel/utils/empty_error_state_widget.dart';

import '../../../main.dart';
import '../../setting/account_setting/components/logout_account_component.dart';
import 'components/add_profile_component.dart';

// ignore: must_be_immutable
class WatchingProfileScreen extends StatelessWidget {
  WatchingProfileScreen({super.key});

  final WatchingProfileController profileWatchingController =
      Get.put(WatchingProfileController(navigateToDashboard: true));
  bool isOpen = false;

  @override
  Widget build(BuildContext context) {
    return AppScaffoldNew(
      hasLeadingWidget: false,
      hideAppBar: true,
      isLoading: profileWatchingController.isLoading,
      scaffoldBackgroundColor: appScreenBackgroundDark,
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(bottom: 120),
            child: Column(
              children: [
                // Top Logo or Image
                kToolbarHeight.toInt().height,
                DynamicAppLogoWidget(
                  size: Size(70, 70),
                  image: appConfigs.value.appLogo,
                ),
                // Image.asset(Assets.assetsAppLogo, height: 36),
                (Get.height * 0.05).toInt().height,

                Obx(
                  () {
                    return SnapHelperWidget(
                      future: profileWatchingController.getProfileFuture.value,
                      loadingWidget: Offstage(),
                      errorBuilder: (error) {
                        return NoDataWidget(
                          titleTextStyle: secondaryTextStyle(color: white),
                          subTitleTextStyle: primaryTextStyle(color: white),
                          title: error,
                          retryText: locale.value.reload,
                          imageWidget: const ErrorStateWidget(),
                          onRetry: () {
                            profileWatchingController.onInit();
                          },
                        ).paddingSymmetric(horizontal: 32).center();
                      },
                      onSuccess: (data) {
                        return RefreshIndicator(
                          color: appColorPrimary,
                          onRefresh: () {
                            return profileWatchingController.getProfilesList();
                          },
                          child: Obx(() {
                            return AnimatedScrollView(
                              listAnimationType: commonListAnimationType,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  locale.value.whoIsWatching,
                                  style: commonW600PrimaryTextStyle(size: 24),
                                ),
                                28.height,
                                Obx(
                                  () => accountProfiles.isNotEmpty
                                      ? AnimatedWrap(
                                          spacing: 16,
                                          runSpacing: 20,
                                          alignment: WrapAlignment.center,
                                          itemCount: accountProfiles.length + 1,
                                          itemBuilder: (context, index) {
                                            if(index == accountProfiles.length) {
                                              return AddWatchingProfileComponent(
                                                profileWatchingController: profileWatchingController,
                                              );
                                            }

                                            // Initialize focus nodes when profiles are loaded
                                            if (profileWatchingController.profileFocusNodes.length !=
                                                accountProfiles.length) {
                                              profileWatchingController
                                                  .initializeProfileFocusNodes(accountProfiles.length);
                                            }

                                            final focusNode = index < profileWatchingController.profileFocusNodes.length
                                                ? profileWatchingController.profileFocusNodes[index]
                                                : null;

                                            final isFocused = profileWatchingController.getFocusState(index);

                                            return Focus(
                                              focusNode: focusNode,
                                              canRequestFocus: true,
                                              autofocus: focusNode == null && index == 0,
                                              onKeyEvent: (node, event) {
                                                if (event is KeyDownEvent) {
                                                  if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                                                    // Move focus to logout button
                                                    profileWatchingController.moveFocusToLogoutButton();
                                                    return KeyEventResult.handled;
                                                  } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                                                    profileWatchingController.moveFocusToNextProfile();
                                                    return KeyEventResult.handled;
                                                  } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                                                    profileWatchingController.moveFocusToPreviousProfile();
                                                    return KeyEventResult.handled;
                                                  } else if (event.logicalKey == LogicalKeyboardKey.select ||
                                                      event.logicalKey == LogicalKeyboardKey.enter) {
                                                    profileWatchingController.handleSelectProfile(
                                                        accountProfiles[index], context);
                                                    return KeyEventResult.handled;
                                                  }
                                                }
                                                return KeyEventResult.ignored;
                                              },
                                              onFocusChange: (value) {
                                                if (value) {
                                                  FocusSoundService.play();
                                                }
                                                profileWatchingController.updateFocusState(index, value);
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
                                                    profile: accountProfiles[index],
                                                    profileWatchingController: profileWatchingController,
                                                    padding: EdgeInsets.zero,
                                                    width: Get.width / 5.5 - 56,
                                                    height: 144,
                                                    imageSize: 65,
                                                    focusNode: null,
                                                    onDownArrowKeyEvent: () {
                                                      profileWatchingController.moveFocusToLogoutButton();
                                                    },
                                                    onRightArrowKeyEvent: () {
                                                      profileWatchingController.moveFocusToNextProfile();
                                                    },
                                                    onLeftArrowKeyEvent: () {
                                                      profileWatchingController.moveFocusToPreviousProfile();
                                                    },
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ).paddingOnly(bottom: 20)
                                      : AddProfileComponent(
                                          profileWatchingController: profileWatchingController,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                          width: Get.width / 5.5 - 56,
                                          height: 144,
                                        ).paddingOnly(bottom: 20),
                                ),
                              ],
                            );
                          }),
                        );
                      },
                    );
                  },
                )
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              width: Get.width,
              color: appBackgroundColorDark,
              alignment: Alignment.center,
              child: Focus(
                  focusNode: profileWatchingController.logoutButtonFocusNode,
                  onFocusChange: (value) {
                    if (value) {
                      FocusSoundService.play();
                    }
                    profileWatchingController.updateLogoutButtonFocus(value);
                  },
                  onKeyEvent: (node, event) {
                    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                      profileWatchingController.moveFocusToFirstProfile();
                      return KeyEventResult.handled;
                    } else if ((event.logicalKey == LogicalKeyboardKey.select ||
                            event.logicalKey == LogicalKeyboardKey.enter) &&
                        !isOpen) {
                      isOpen = true;
                      Get.bottomSheet(
                        isDismissible: true,
                        isScrollControlled: true,
                        enableDrag: false,
                        LogoutAccountComponent(
                          device: currentDevice.value.deviceId,
                          deviceName: currentDevice.value.deviceName,
                          onLogout: (logoutAll) async {
                            profileWatchingController.logoutCurrentUser();
                          },
                        ),
                      ).then((value) async {
                        await Future.delayed(const Duration(seconds: 1));
                        isOpen = false;
                      });
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.handled;
                  },
                  child: Obx(
                    () => Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: profileWatchingController.isLogoutButtonFocused.value
                            ? Border.all(color: Colors.white, width: 2)
                            : Border.all(color: Colors.transparent, width: 0),
                      ),
                      child: TextButton(
                        onPressed: null,
                        child: Text(
                          locale.value.logout,
                          style: boldTextStyle(color: appColorPrimary, size: 22),
                        ),
                      ),
                    ),
                  )),
            ),
          ),
        ],
      ),
    );
  }
}


class AddWatchingProfileComponent extends StatelessWidget {
  final WatchingProfileController profileWatchingController;

  AddWatchingProfileComponent({
    super.key,
    required this.profileWatchingController,
  });

  final RxBool isFocused = false.obs;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: profileWatchingController.addProfileFocusNode,
      onFocusChange: (value) {
        isFocused(value);
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
            profileWatchingController.handleAddEditProfile(WatchingProfileModel(), false);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            profileWatchingController.profileFocusNodes.last.requestFocus();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            profileWatchingController.moveFocusToLogoutButton();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.handled;
      },
      child: Obx(
        () => Container(
          width: Get.width / 5.5 - 24,
          height: 176,
          decoration: boxDecorationDefault(
            borderRadius: radius(4),
            color: cardColor,
            border: focusBorder(isFocused.value),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: Get.width * 0.12,
                width: Get.width * 0.12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: btnColor,
                ),
                child: const Icon(
                  Icons.add,
                  color: iconColor,
                  size: 40,
                ),
              ),
              10.height,
              Marquee(
                child: Text(
                  locale.value.addProfile,
                  textAlign: TextAlign.center,
                  style: boldTextStyle()  ,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
