import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/screens/coming_soon/model/coming_soon_response.dart';
import 'package:streamit_laravel/utils/colors.dart';
import 'package:streamit_laravel/utils/common_base.dart';
import 'package:streamit_laravel/generated/assets.dart';
import '../../../components/cached_image_widget.dart';
import '../../../main.dart';
import '../../../utils/app_common.dart';
import '../coming_soon_controller.dart';
import '../coming_soon_detail_screen.dart';

class ComingSoonComponent extends StatelessWidget {
  final ComingSoonModel comingSoonDet;
  final ComingSoonController comingSoonCont;
  final bool isLoading;

  const ComingSoonComponent({
    super.key,
    required this.comingSoonDet,
    this.isLoading = false,
    required this.comingSoonCont,
  });

  @override
  Widget build(BuildContext context) {
    final RxBool hasFocus = false.obs;

    return InkWell(
      autofocus: true,
      canRequestFocus: true,
      onFocusChange: (value) {
        hasFocus(value);
      },
      onTap: () {
        doIfLogin(onLoggedIn: () {
          comingSoonCont.listContent;
          Get.to(
            () => ComingSoonDetailScreen(
              comingSoonCont: comingSoonCont,
              comingSoonData: comingSoonDet,
            ),
          );
        });
      },
      child: Obx(
        () => Container(
          width: Get.width * 0.8,
          height: 200,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: boxDecorationDefault(borderRadius: BorderRadius.circular(8), color: canvasColor, border: focusBorder(hasFocus.value)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CachedImageWidget(
                    fit: BoxFit.cover,
                    url: comingSoonDet.thumbnailImage,
                    height: 200,
                    width: 300,
                  ).cornerRadiusWithClipRRectOnly(topLeft: 8, bottomLeft: 8),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: boxDecorationDefault(
                            borderRadius: BorderRadius.circular(4),
                            color: btnColor,
                          ),
                          child: Text(
                            locale.value.trailer,
                            style: commonW600SecondaryTextStyle(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                decoration: boxDecorationDefault(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  color: canvasColor,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (comingSoonDet.genres.validate().isNotEmpty)
                              Text(
                                comingSoonDet.genre.validate(),
                                style: commonSecondaryTextStyle(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            4.height,
                            Text(
                              comingSoonDet.name.validate(),
                              style: commonW500PrimaryTextStyle(size: 24),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ).expand(),
                      ],
                    ),
                    16.height,
                    Row(
                      children: [
                        if (comingSoonDet.seasonName.toString().isNotEmpty) ...[
                          Text(
                            comingSoonDet.seasonName,
                            maxLines: 1,
                            style: commonSecondaryTextStyle(),
                          ),
                          24.width,
                        ],
                        const CachedImageWidget(
                          url: Assets.iconsIcTranslate,
                          height: 16,
                          width: 16,
                        ),
                        8.width,
                        Text(
                          comingSoonDet.language.capitalizeFirstLetter(),
                          style: secondaryTextStyle(
                            size: 14,
                            color: darkGrayTextColor,
                            weight: FontWeight.w800,
                          ),
                        ),
                        24.width,
                        if (comingSoonDet.isRestricted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: boxDecorationDefault(
                              borderRadius: BorderRadius.circular(4),
                              color: white,
                            ),
                            child: Text(
                              locale.value.ua18.suffixText(value: "+"),
                              style: boldTextStyle(size: 12, color: Colors.black),
                            ),
                          ),
                      ],
                    ),
                    16.height,
                    if (comingSoonDet.description.isNotEmpty) Text(comingSoonDet.description, style: commonSecondaryTextStyle(color: descriptionTextColor), maxLines: 4, overflow: TextOverflow.ellipsis).expand(),
                  ],
                ),
              ).expand(),
            ],
          ),
        ),
      ),
    );
  }

  Widget getRemindIcon() {
    try {
      return Lottie.asset(
        Assets.lottieRemind,
        height: 28,
        repeat: comingSoonDet.isRemind.getBoolInt() ? false : true,
      );
    } catch (e) {
      return const CachedImageWidget(
        url: Assets.iconsIcBell,
        height: 18,
        width: 18,
      );
    }
  }
}
