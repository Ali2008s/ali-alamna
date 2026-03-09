// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/components/app_scaffold.dart';
import 'package:streamit_laravel/generated/assets.dart';

import '../../components/cached_image_widget.dart';
import '../../main.dart';
import '../../utils/colors.dart';
import '../../utils/common_base.dart';
import '18_plus_controller.dart';

class EighteenPlusCard extends StatelessWidget {
  EighteenPlusCard({super.key});

  final EighteenPlusController eighteenPlusCont = Get.put(EighteenPlusController());

  @override
  Widget build(BuildContext context) {
    return AppScaffoldNew(
      hideAppBar: true,
      body: Container(
        width: double.infinity,
        decoration: boxDecorationDefault(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          border: Border(top: BorderSide(color: borderColor.withValues(alpha: 0.8))),
          color: appScreenBackgroundDark,
        ),
        child: AnimatedScrollView(
          crossAxisAlignment: CrossAxisAlignment.center,
          padding: const EdgeInsets.only(left: 32, right: 32, top: 32, bottom: 32),
          mainAxisSize: MainAxisSize.min,
          children: [
            const CachedImageWidget(url: Assets.iconsIcCircleCheck, height: 80, width: 80, circle: true),
            8.height,

            ///TODO: Add localization
            Text('Control Your Viewing Experience', style: commonW500PrimaryTextStyle(size: 18)),
            8.height,
            Obx(
              () => Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Focus(
                      focusNode: eighteenPlusCont.checkBoxFNode,
                      autofocus: false,
                      canRequestFocus: true,
                      onFocusChange: eighteenPlusCont.onCheckBoxFocusChange,
                      onKeyEvent: eighteenPlusCont.onCheckBoxKeyEvent,
                      child: GestureDetector(
                        onTap: eighteenPlusCont.toggleCheckBox,
                        child: Container(
                          decoration: BoxDecoration(
                            border: eighteenPlusCont.isCheckBoxFocused.value ? Border.all(color: white, width: 1) : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Container(
                            height: 16,
                            width: 16,
                            padding: const EdgeInsets.all(2),
                            decoration: boxDecorationDefault(
                              borderRadius: BorderRadius.circular(2),
                              color: eighteenPlusCont.is18Plus.isTrue ? appColorPrimary : white,
                              border: eighteenPlusCont.isCheckBoxFocused.value ? Border.all(color: appColorPrimary, width: 1, strokeAlign: BorderSide.strokeAlignCenter) : null,
                            ),
                            child: const Icon(Icons.check, color: white, size: 12),
                          ),
                        ),
                      ),
                    ),
                    12.width,
                    Transform.translate(offset: Offset(0, -2), child: Text('Would you like to include 18+ rated content in your profile recommendations?', style: primaryTextStyle())),
                  ],
                ),
              ),
            ),
            24.height,
            Row(
              children: [
                Spacer(),
                Obx(
                  () => Focus(
                    focusNode: eighteenPlusCont.noBtnFNode,
                    canRequestFocus: eighteenPlusCont.is18Plus.isTrue,
                    onFocusChange: eighteenPlusCont.onNoBtnFocusChange,
                    onKeyEvent: eighteenPlusCont.onNoBtnKeyEvent,
                    child: AppButton(
                      height: Get.height * 0.07,
                      padding: EdgeInsets.all(16),
                      text: locale.value.no,
                      color: lightBtnColor,
                      textStyle: appButtonTextStyleWhite,
                      shapeBorder: RoundedRectangleBorder(
                        borderRadius: radius(6),
                        side: eighteenPlusCont.isNoBtnFocused.value ? BorderSide(color: white, width: 3, strokeAlign: BorderSide.strokeAlignOutside) : BorderSide.none,
                      ),
                      onTap: eighteenPlusCont.noBtnClick,
                    ),
                  ),
                ).expand(),
                16.width,
                Obx(
                  () => Focus(
                    focusNode: eighteenPlusCont.yesBtnFNode,
                    autofocus: true,
                    canRequestFocus: eighteenPlusCont.is18Plus.isTrue,
                    onFocusChange: eighteenPlusCont.onYesBtnFocusChange,
                    onKeyEvent: eighteenPlusCont.onYesBtnKeyEvent,
                    child: AppButton(
                      height: Get.height * 0.07,
                      padding: EdgeInsets.all(16),
                      text: locale.value.yes,
                      color: eighteenPlusCont.is18Plus.isTrue ? appColorPrimary : lightBtnColor,
                      textStyle: appButtonTextStyleWhite,
                      shapeBorder: RoundedRectangleBorder(
                        borderRadius: radius(6),
                        side: eighteenPlusCont.isYesBtnFocused.value ? BorderSide(color: white, width: 3, strokeAlign: BorderSide.strokeAlignOutside) : BorderSide.none,
                      ),
                      onTap: eighteenPlusCont.yesBtnClick,
                    ),
                  ),
                ).expand(),
                Spacer(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
