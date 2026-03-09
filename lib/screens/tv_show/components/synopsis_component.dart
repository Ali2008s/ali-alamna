import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/components/cached_image_widget.dart';
import 'package:streamit_laravel/generated/assets.dart';
import 'package:streamit_laravel/main.dart';
import 'package:streamit_laravel/screens/tv_show/tv_show_detail_controller.dart';
import 'package:streamit_laravel/utils/colors.dart';
import 'package:streamit_laravel/utils/common_base.dart' show commonSecondaryTextStyle;

class TvShowSynopsisComponent extends StatelessWidget  {
  final TvShowPreviewController tvShowPreviewCont;
  const TvShowSynopsisComponent({super.key, required this.tvShowPreviewCont});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 230, 50, 0),
        child: SizedBox(
          width: Get.width * 0.45,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tvShowPreviewCont.tvShowDetail.value.details.genres.isNotEmpty)
                Marquee(
                  child: Text(tvShowPreviewCont.tvShowDetail.value.details.genres.join(' • '), style: commonSecondaryTextStyle(size: 16)),
                ),
              if (tvShowPreviewCont.tvShowDetail.value.details.genres.isNotEmpty) 8.height,
              Obx(() => Text(tvShowPreviewCont.tvShowDetail.value.details.name, style: boldTextStyle(size: 34, color: white))),
              8.height,
              Obx(() => Row(
                children: [
                  Text(
                    "${tvShowPreviewCont.tvShowDetail.value.details.releaseDate}  •  ${tvShowPreviewCont.tvShowDetail.value.details.language.capitalizeFirstLetter()}  •  ${tvShowPreviewCont.tvShowDetail.value.details.seasonList.length} ${tvShowPreviewCont.tvShowDetail.value.details.seasonList.length > 1 ? 'Seasons' : 'Season'}",
                    style: primaryTextStyle(color: white.withAlpha((0.8 * 255).toInt()), size: 18),
                  ),
                  10.width,
                  if (tvShowPreviewCont.tvShowDetail.value.details.imdbRating != "") const CachedImageWidget(url: Assets.iconsIcStar, height: 14, width: 14),
                  6.width,
                  if (tvShowPreviewCont.tvShowDetail.value.details.imdbRating != "") Transform.translate(offset: Offset(0, 2), child: Text("${tvShowPreviewCont.tvShowDetail.value.details.imdbRating} ${locale.value.iMDB}", style: primaryTextStyle(color: white.withAlpha((0.8 * 255).toInt()), size: 18),)),
                ],
              )),
              8.height,
              Obx(() => Text(tvShowPreviewCont.tvShowDetail.value.details.contentRating, style: secondaryTextStyle(color: white.withAlpha((0.8 * 255).toInt()), size: 16))),
              8.height,
              Obx(() => Text(
                tvShowPreviewCont.tvShowDetail.value.details.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: secondaryTextStyle(color: white.withValues(alpha: 0.85), size: 16),
              )),
              16.height,
              /// Watch Now button
              Focus(
                focusNode: tvShowPreviewCont.watchNowFocus,
                onFocusChange: tvShowPreviewCont.handleWatchNowFocusChange,
                onKeyEvent: tvShowPreviewCont.handleWatchNowKey,
                child: Obx(() => AnimatedContainer(
                  width: Get.width * 0.428,
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: appColorPrimary.withValues(alpha: 0.8),
                    borderRadius: radius(6),
                    border: tvShowPreviewCont.isWatchNowFocused.value ? Border.all(color: white.withValues(alpha: 0.8), width: 2) : null,
                  ),
                ///TODO: add localization
                  child: Obx(() {
                    final int seasonNo = tvShowPreviewCont.currentSeason.value > 0 ? tvShowPreviewCont.currentSeason.value : 1;
                    final int episodeNo = tvShowPreviewCont.currentEpisodeIndex.value >= 0 ? (tvShowPreviewCont.currentEpisodeIndex.value + 1) : 1;
                    return Text('Start Watching S${seasonNo}E$episodeNo', style: boldTextStyle(color: white, size: 24), textAlign: TextAlign.center);
                  }),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
