import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/main.dart';
import 'package:streamit_laravel/screens/profile/watching_profile/model/profile_watching_model.dart';
import 'package:streamit_laravel/screens/profile/watching_profile/watching_profile_controller.dart';
import 'package:streamit_laravel/utils/app_common.dart';
import 'package:streamit_laravel/utils/colors.dart';
import 'package:streamit_laravel/utils/common_base.dart';

class AddProfileComponent extends StatelessWidget {
  final WatchingProfileController profileWatchingController;
  final double height;
  final double width;
  final EdgeInsets padding;

  AddProfileComponent({
    super.key,
    required this.profileWatchingController,
    required this.height,
    required this.width,
    required this.padding,
  });

  final RxBool isFocused = false.obs;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      autofocus: true,
      focusColor: white.withValues(alpha: 0.6),
      onFocusChange: (value) {
        isFocused(value);
      },
      onTap: () {
        profileWatchingController.handleAddEditProfile(WatchingProfileModel(), false);
      },
      child: Obx(
        () => Container(
          height: Get.height * 0.24,
          width: Get.width * 0.12,
          padding: padding,
          decoration: boxDecorationDefault(
            borderRadius: radius(4),
            color: cardColor,
            border: focusBorder(isFocused.value),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: btnColor,
                ),
                padding: const EdgeInsets.all(16),
                child: const Icon(
                  Icons.add,
                  color: iconColor,
                ),
              ),
              8.height,
              Marquee(
                child: Text(
                  locale.value.addProfile,
                  textAlign: TextAlign.center,
                  style: commonW500PrimaryTextStyle(size: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
