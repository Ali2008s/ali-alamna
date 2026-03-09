import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/main.dart';
import 'package:streamit_laravel/screens/profile/components/delete_profile_component.dart';
import 'package:streamit_laravel/screens/profile/watching_profile/watching_profile_controller.dart';
import 'package:streamit_laravel/utils/colors.dart';
import 'package:streamit_laravel/utils/common_base.dart';
import 'package:streamit_laravel/generated/assets.dart';

class AddUpdateProfileDialogComponent extends StatelessWidget {
  final bool isEdit;

  AddUpdateProfileDialogComponent({super.key, required this.isEdit});

  final WatchingProfileController profileWatchingController = Get.find<WatchingProfileController>();

  @override
  Widget build(BuildContext context) {
    profileWatchingController.picFocusNode.requestFocus();
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: boxDecorationDefault(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        border: Border(top: BorderSide(color: borderColor.withValues(alpha: 0.8))),
        color: appScreenBackgroundDark,
      ),
      child: Form(
        key: profileWatchingController.editFormKey,
        child: AnimatedScrollView(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            8.height,
            Stack(
              children: [
                Container(
                  height: 100,
                  width: Get.width,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        context.cardColor.withValues(alpha: 0.6),
                        Color(0x001A1A1A), // rgba(26, 26, 26, 0) for the middle (transparent)
                        context.cardColor.withValues(alpha: 0.6)
                      ],
                      stops: [0.0242, 0.4951, 0.986], // These are the stops matching your percentage values
                    ),
                  ),
                ),
                SizedBox(
                  height: 100,
                  child: Focus(
                    focusNode: profileWatchingController.picFocusNode,
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent) {
                        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                          if (profileWatchingController.currentIndex.value > 0) {
                            profileWatchingController.pageController.previousPage(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                          if (profileWatchingController.currentIndex.value < profileWatchingController.defaultProfileImage.length - 1) {
                            profileWatchingController.pageController.nextPage(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                          profileWatchingController.nameFocusNode.requestFocus();
                        }
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: PageView.builder(
                      physics: BouncingScrollPhysics(),
                      controller: profileWatchingController.pageController,
                      onPageChanged: (page) {
                        // Delay the index update slightly to avoid rebuild conflicts
                        Future.microtask(() {
                          profileWatchingController.currentIndex(page);
                          profileWatchingController.updateCenterImage(
                            profileWatchingController.defaultProfileImage[page],
                          );
                        });
                      },
                      itemCount: profileWatchingController.defaultProfileImage.length,
                      itemBuilder: (context, index) {
                        return Obx(() {
                          bool isCenter = index == profileWatchingController.currentIndex.value;

                          return Center(
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 200),
                              height: isCenter ? 80 : 50,
                              width: isCenter ? 80 : 50,
                              margin: EdgeInsets.symmetric(horizontal: 8, vertical: isCenter ? 0 : 16),
                              decoration: boxDecorationDefault(
                                shape: BoxShape.circle,
                                borderRadius: isCenter ? BorderRadius.circular(20) : null,
                                border: isCenter ? Border.all(color: appColorPrimary, width: 2) : null,
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: profileWatchingController.getImageProvider(
                                    isCenter ? profileWatchingController.centerImagePath.value : profileWatchingController.defaultProfileImage[index],
                                  ),
                                ),
                              ),
                            ),
                          );
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            16.height,
            KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (event) {
                try {
                  if (event is KeyDownEvent) {
                    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                      profileWatchingController.picFocusNode.requestFocus();
                    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                      profileWatchingController.cancelBtnFocusNode.requestFocus();
                    }
                  }
                } catch (e) {
                  log('error in KeyboardListener: $e');
                }
              },
              child: AppTextField(
                textFieldType: TextFieldType.NAME,
                focus: profileWatchingController.nameFocusNode,
                controller: profileWatchingController.saveNameController,
                isValidationRequired: true,
                textStyle: secondaryTextStyle(color: primaryTextColor),
                decoration: inputDecoration(
                  context,
                  hintText: locale.value.firstName,
                  contentPadding: const EdgeInsets.only(top: 14),
                  prefixIcon: Image.asset(
                    Assets.iconsIcAccount,
                    color: primaryTextColor,
                    height: 12,
                    width: 12,
                  ).paddingAll(16),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return locale.value.nameCannotBeEmpty;
                  }
                  return null;
                },
                onChanged: (p0) {
                  profileWatchingController.saveNameController.text = p0;
                  profileWatchingController.getBtnEnable();
                },
                onFieldSubmitted: (p0) {
                  profileWatchingController.saveNameController.text = p0;
                  profileWatchingController.getBtnEnable();
                  profileWatchingController.saveBtnBtnFocusNode.requestFocus();
                },
              ).paddingSymmetric(horizontal: 24),
            ),
            16.height,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Obx(
                  () => Focus(
                    focusNode: profileWatchingController.cancelBtnFocusNode,
                    onFocusChange: (value) {
                      profileWatchingController.isCancelBtnFocused(value);
                    },
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent) {
                        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                          profileWatchingController.nameFocusNode.requestFocus();
                          return KeyEventResult.handled;
                        }
                        if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
                          cancelBtnClick();
                          return KeyEventResult.handled;
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: profileWatchingController.isCancelBtnFocused.value ? white : transparentColor,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextButton(
                        onPressed: cancelBtnClick,
                        child: Text(
                          isEdit ? locale.value.remove : locale.value.cancel,
                          style: commonW600SecondaryTextStyle(),
                        ),
                      ),
                    ),
                  ),
                ),
                Obx(
                  () => Focus(
                    focusNode: profileWatchingController.saveBtnBtnFocusNode,
                    onFocusChange: (value) {
                      profileWatchingController.isSaveBtnFocused(value);
                    },
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent) {
                        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                          profileWatchingController.nameFocusNode.requestFocus();
                          return KeyEventResult.handled;
                        }
                        if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
                          saveBtnClick();
                          return KeyEventResult.handled;
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                    child: AppButton(
                      shapeBorder: RoundedRectangleBorder(
                        borderRadius: radius(6),
                        side: profileWatchingController.isSaveBtnFocused.value ? BorderSide(color: white, width: 3, strokeAlign: BorderSide.strokeAlignOutside) : BorderSide.none,
                      ),
                      color: profileWatchingController.isBtnEnable.value ? appColorPrimary : lightBtnColor,
                      onTap: saveBtnClick,
                      child: Text(
                        isEdit ? locale.value.update : locale.value.save,
                        style: appButtonTextStyleWhite,
                      ),
                    ),
                  ),
                ),
              ],
            ).paddingSymmetric(horizontal: 16),
          ],
        ),
      ),
    );
  }

  Future<void> saveBtnClick() async {
    Get.back();
    if (profileWatchingController.editFormKey.currentState!.validate()) {
      profileWatchingController.getBtnEnable();

      await profileWatchingController.editUserProfile(isEdit, name: profileWatchingController.saveNameController.text);
    }
  }

  Future<void> cancelBtnClick() async {
    Get.back();
    if (isEdit) {
      profileWatchingController.saveNameController.clear();

      Get.back();
      Get.bottomSheet(
        isDismissible: true,
        isScrollControlled: true,
        enableDrag: false,
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: DeleteProfileComponent(
            onDeleteAccount: () async {
              Get.back();
              await profileWatchingController.deleteUserProfile(profileWatchingController.selectedProfile.value.id.toString(), isFromProfileWatching: false);
            },
            profileName: profileWatchingController.selectedProfile.value.name,
          ),
        ),
      );
    }
  }
}