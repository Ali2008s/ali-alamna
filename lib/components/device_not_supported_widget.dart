import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/main.dart';

import '../generated/assets.dart';

class DeviceNotSupportedComponent extends StatelessWidget {
  final double? height;
  final double? width;
  final String title;

  const DeviceNotSupportedComponent({super.key, this.height, this.width, required this.title});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          width: width ?? Get.width,
          height: height ?? Get.height,
          child: Column(  
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              42.height,
              Image.asset(
                Assets.imagesIcDeviceNotSupported,
                height: 100,
                width: 100,
              ),
              8.height,
              Text(locale.value.yourDeviceIsNot, style: boldTextStyle()),
              2.height,
              Text(locale.value.pleaseSubscribeOrUpgrade, style: primaryTextStyle()),
            ],
          ),
        ),
      ],
    );
  }
}
