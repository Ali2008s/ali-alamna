import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/components/shimmer_widget.dart';

import '../../../utils/colors.dart';

class ShimmerUnlockedVideo extends StatelessWidget {
  const ShimmerUnlockedVideo({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedScrollView(
      refreshIndicatorColor: appColorPrimary,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(left: Get.width * 0.04, right: Get.width * 0.04, bottom: Get.height * 0.02),
      children: [
        AnimatedWrap(spacing: Get.width * 0.03, runSpacing: Get.height * 0.02, children: [
          ...List.generate(
            20,
            (index) {
              return ShimmerWidget(
                height: 150,
                width: Get.width * 0.286,
                radius: 6,
              );
            },
          ),
        ]),
      ],
    );
  }
}
