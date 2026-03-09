import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/utils/colors.dart';
import 'package:streamit_laravel/utils/common_base.dart';

import '../../main.dart';
import 'choose_option_screen.dart';
import 'walk_through_cotroller.dart';

class WalkThroughScreen extends StatelessWidget {
  final WalkThroughController walkThroughCont = Get.put(WalkThroughController());

  WalkThroughScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: appScreenBackgroundDark,
      body: SizedBox(
        width: screenWidth,
        height: screenHeight,
        child: Obx(
          () => Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight * 0.02), // Dynamic spacing
              walkThroughCont.currentPosition.value == walkThroughCont.pages.length
                  ? const Offstage()
                  : Align(
                      alignment: Alignment.topRight,
                      child: TextButton(
                        onPressed: () {
                          Get.offAll(() => const ChooseOptionScreen(), duration: const Duration(milliseconds: 500), curve: Curves.linearToEaseOut);
                        },
                        child: Text(
                          locale.value.lblSkip,
                          style: primaryTextStyle(color: appColorPrimary, size: 16),
                        ),
                      ).paddingOnly(top: screenHeight * 0.02, right: screenWidth * 0.02),
                    ),
              SizedBox(height: screenHeight * 0.01),
              PageView.builder(
                itemCount: walkThroughCont.pages.length,
                itemBuilder: (BuildContext context, int index) {
                  WalkThroughModelClass page = walkThroughCont.pages[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        page.image.validate(),
                        width: screenWidth * 0.8, // Adjust image size
                        height: screenHeight * 0.5,
                        fit: BoxFit.contain,
                      ).expand(),
                      SizedBox(height: screenHeight * 0.02),
                      Text(
                        page.title.toString(),
                        textAlign: TextAlign.center,
                        style: commonW500PrimaryTextStyle(size: (screenWidth * 0.05).toInt()), // Dynamic font size
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        page.subTitle.toString(),
                        textAlign: TextAlign.center,
                        style: secondaryTextStyle(size: (screenWidth * 0.04).toInt()),
                      ),
                    ],
                  );
                },
                controller: walkThroughCont.pageController.value,
                scrollDirection: Axis.horizontal,
                onPageChanged: (int num) {
                  walkThroughCont.currentPosition.value = num + 1;
                },
              ).expand(),
              SizedBox(height: screenHeight * 0.02),
              DotIndicator(
                pageController: walkThroughCont.pageController.value,
                pages: walkThroughCont.pages,
                indicatorColor: white,
                unselectedIndicatorColor: white.withValues(alpha: 0.5),
                currentBoxShape: BoxShape.circle,
                boxShape: BoxShape.circle,
                dotSize: screenWidth * 0.015, // Dynamic dot size
                currentDotSize: screenWidth * 0.02,
              ),
              SizedBox(height: screenHeight * 0.02),
              AppButton(
                margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                width: screenWidth * 0.6,
                text: walkThroughCont.currentPosition.value == walkThroughCont.pages.length ? locale.value.lblGetStarted : locale.value.lblNext,
                color: appColorPrimary,
                textStyle: appButtonTextStyleWhite.copyWith(fontSize: screenWidth * 0.045),
                shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.02)),
                onTap: () async {
                  if (walkThroughCont.currentPosition.value == walkThroughCont.pages.length) {
                    Get.offAll(() => const ChooseOptionScreen(), duration: const Duration(milliseconds: 500), curve: Curves.linearToEaseOut);
                  } else {
                    walkThroughCont.pageController.value.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.linearToEaseOut);
                  }
                },
              ),
            ],
          ).paddingAll(screenWidth * 0.05),
        ),
      ),
    );
  }
}
