import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/main.dart';
import 'package:streamit_laravel/generated/assets.dart';
import '../components/app_scaffold.dart';
import '../components/loader_widget.dart';
import '../utils/colors.dart';
import 'splash_controller.dart';

class SplashScreen extends StatelessWidget {
  final String deepLink;
  final bool? link;

  SplashScreen({super.key, this.deepLink = "", this.link});

  /// دائماً احذف الـ Controller القديم وأنشئ واحداً جديداً
  /// هذا يحل مشكلة التوقف عند إعادة الدخول
  SplashScreenController get splashController {
    if (Get.isRegistered<SplashScreenController>()) {
      Get.delete<SplashScreenController>(force: true);
    }
    return Get.put(SplashScreenController());
  }

  @override
  Widget build(BuildContext context) {
    final controller = splashController;

    if (link == true) {
      controller.handleDeepLinking(deepLink: deepLink);
    }
    return AppScaffold(
      hideAppBar: true,
      scaffoldBackgroundColor: appScreenBackgroundDark,
      body: SizedBox(
        height: Get.height,
        width: Get.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              Assets.assetsAppLogo,
              height: 56,
            ).center(),
            Obx(
              () => controller.isLoading.value
                  ? LoaderWidget().center()
                  : TextButton(
                      child: Text(locale.value.reload, style: boldTextStyle()),
                      onPressed: () {
                        controller.init(showLoader: true);
                      },
                    ).visible(controller.appNotSynced.isTrue),
            )
          ],
        ),
      ),
    );
  }
}
