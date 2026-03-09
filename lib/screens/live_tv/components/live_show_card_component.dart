import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/utils/app_common.dart';
import 'package:streamit_laravel/utils/constants.dart';
import '../../../components/cached_image_widget.dart';
import '../../../generated/assets.dart';
import '../../../utils/colors.dart';
import '../model/live_tv_dashboard_response.dart';
import 'live_card.dart';

class LiveShowCardComponent extends StatelessWidget {
  final double? height;
  final double? width;
  final ChannelModel liveShowDet;

  const LiveShowCardComponent({super.key, required this.liveShowDet, this.height, this.width});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CachedImageWidget(
          url: liveShowDet.posterTvImage,
          height: height ?? 150,
          width: width ?? 180,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
        const Positioned(
          left: 8,
          top: 8,
          child: LiveCard(),
        ),
        if (liveShowDet.access == MovieAccess.paidAccess && liveShowDet.requiredPlanLevel != 0 && currentSubscription.value.level < liveShowDet.requiredPlanLevel)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              height: 18,
              width: 18,
              padding: const EdgeInsets.all(4),
              decoration: boxDecorationDefault(shape: BoxShape.circle, color: yellowColor),
              child: const CachedImageWidget(
                url: Assets.iconsIcVector,
              ),
            ),
          ),
      ],
    );
  }
}
