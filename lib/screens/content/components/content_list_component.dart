import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/generated/assets.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';
import 'package:streamit_laravel/utils/colors.dart';

import '../../../components/cached_image_widget.dart';
import '../../../main.dart';
import '../../../utils/app_common.dart';
import '../../../utils/constants.dart';
import '../../coming_soon/coming_soon_controller.dart';
import '../../coming_soon/coming_soon_detail_screen.dart';
import '../../coming_soon/model/coming_soon_response.dart';
import '../../live_tv/live_tv_details/live_tv_details_screen.dart';
import '../content_details_screen.dart';

class ContentListComponent extends StatelessWidget {
  final PosterDataModel contentData;
  final int topTenIndex;
  final bool isLoading;
  final VoidCallback? onTap;
  final bool isHorizontalList;

  const ContentListComponent({
    super.key,
    required this.contentData,
    this.topTenIndex = -1,
    this.isLoading = false,
    this.onTap,
    this.isHorizontalList = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: onTap ??
              () {
            if (isLoading) return;

            if (contentData.details.releaseDate.isNotEmpty && isComingSoon(contentData.details.releaseDate)) {
              final ComingSoonController comingSoonCont = Get.find<ComingSoonController>();
              Get.to(
                    () => ComingSoonDetailScreen(
                  comingSoonCont: comingSoonCont,
                  comingSoonData: ComingSoonModel.fromJson(contentData.details.toListJson()),
                ),
              );
            } else if (contentData.details.type == VideoType.liveTv) {
              Get.to(
                    () => LiveShowDetailsScreen(),
                arguments: contentData,
              );
            } else {
              Get.to(() => ContentDetailsScreen(), arguments: contentData);
            }
          },
      child: Stack(
        children: [
          CachedImageWidget(
            height: Get.height * 0.16,
            width: isHorizontalList ? Get.width / 4 : Get.width / 3 - 24,
            url: contentData.posterImage,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            radius: 6,
          ),
          if (topTenIndex > -1)
            Container(
              height: Get.height * 0.16,
              width: isHorizontalList ? Get.width / 4 : Get.width / 3 - 24,
              decoration: BoxDecoration(
                borderRadius: radius(6),
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    black.withValues(alpha: 0.3),
                    black.withValues(alpha: 1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          if (contentData.details.access == MovieAccess.paidAccess || !contentData.details.hasContentAccess.getBoolInt())
            Positioned(
              right: 6,
              top: 4,
              child: Container(
                height: 14,
                width: 14,
                padding: const EdgeInsets.all(4),
                decoration: boxDecorationDefault(shape: BoxShape.circle, color: yellowColor),
                child: const CachedImageWidget(url: Assets.iconsIcVector),
              ),
            ),
          if (topTenIndex > -1)
            Positioned(
              left: 0,
              bottom: 0,
              child: CachedImageWidget(
                url: top10Icons[topTenIndex],
                height: Get.height * 0.08,
              ),
            ),
          if (contentData.details.access == MovieAccess.payPerView)
            Positioned(
              right: 6,
              top: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: boxDecorationDefault(
                  borderRadius: BorderRadius.circular(4),
                  color: rentedColor,
                ),
                child: Row(
                  spacing: 4,
                  children: [
                    const CachedImageWidget(
                      url: Assets.iconsIcRent,
                      height: 8,
                      width: 8,
                      color: Colors.white,
                    ),
                    Text(
                      contentData.details.hasContentAccess.getBoolInt() ? locale.value.rented : locale.value.rent,
                      style: secondaryTextStyle(color: white, size: 10),
                    ),
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }
}