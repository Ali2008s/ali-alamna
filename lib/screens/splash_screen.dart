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
      scaffoldBackgroundColor: const Color(0xFF0A0A14),
      body: Container(
        height: Get.height,
        width: Get.width,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0A14),
              Color(0xFF12121F),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // لوكو عالمنا الجديد
            Image.asset(
              'assets/images/logo_splas.png',
              height: 200,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => Image.asset(
                Assets.assetsAppLogo,
                height: 100,
                errorBuilder: (c, e, s) => const Icon(Icons.play_circle_fill, color: appColorPrimary, size: 80),
              ),
            ).center(),
            const SizedBox(height: 20),
            Text(
              "عالمنا",
              style: boldTextStyle(color: Colors.white70, size: 18),
            ).center(),
            const SizedBox(height: 40),
            Obx(
              () => controller.isLoading.value
                  ? LoaderWidget().center()
                  : TextButton(
                      child: Text(locale.value.reload, style: boldTextStyle()),
                      onPressed: () {
                        controller.init(showLoader: true);
                      },
                    ).visible(controller.appNotSynced.isTrue),
            ),
          ],
        ),
      ),
    );
  }
}
