import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/generated/assets.dart';
import 'package:streamit_laravel/main.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';
import 'package:streamit_laravel/utils/colors.dart';
import 'package:streamit_laravel/utils/common_base.dart';
import 'package:streamit_laravel/utils/constants.dart';
import 'package:streamit_laravel/utils/extension/string_extension.dart';

import '../../components/cached_image_widget.dart';
import '../live_tv/components/live_card.dart';
import '../tv_show/trailer_video_player.dart';

class SliderBannerContent extends StatelessWidget {
  final PosterDataModel data;
  final bool showTrailer;
  final VoidCallback onPosterTap;
  final VoidCallback onTrailerEnded;
  final bool hasFocus;

  const SliderBannerContent({super.key, required this.data, required this.showTrailer, required this.onPosterTap, required this.onTrailerEnded, required this.hasFocus});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          right: 0,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedImageWidget(  
                url: data.posterImage,
                width: 1024,
                fit: BoxFit.cover,
                height: Get.height * 0.5,
                alignment: Alignment.centerRight,
              ).onTap(onPosterTap),
              if (showTrailer)
                Positioned.fill(
                  child: TrailerPlayerWidget(
                    videoModel: ContentModel(
                      details: data.details,
                      downloadData: DownloadDataModel(downloadQualities: DownloadQualities()),
                      trailerData: (data.details.trailerUrl?.isNotEmpty ?? false)
                          ? [
                              VideoData(
                                url: data.details.trailerUrl ?? '',
                                urlType: (data.details.trailerUrl ?? '').getUrlTypeFromUrl(data.details.trailerUrlType),
                              )
                            ]
                          : [],
                    ),
                    aspectRatio: Get.width / (Get.height * 0.62),
                    onEnded: onTrailerEnded,
                  ),
                ),
            ],
          ),
        ),
        IgnorePointer(
          ignoring: true,
          child: Container(
            height: Get.height * 0.62,
            width: Get.width,
            foregroundDecoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Colors.black.withValues(alpha: 0.9), Colors.transparent],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: const [0.0, 0.05, 1],
              ),
            ),
          ),
        ),
        if (data.details.type == VideoType.liveTv) const Positioned(top: 14, left: 46, child: LiveCard()),
        Positioned(
          bottom: 8,
          left: 20,
          right: Get.width * 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (data.details.genres.isNotEmpty)
                Marquee(
                  child: Text(data.details.genres.join(' • '), style: commonSecondaryTextStyle(size: 12)),
                ),
              if (data.details.genres.isNotEmpty) 8.height,
              Text(
                data.details.name,
                style: commonW500PrimaryTextStyle(size: 28).copyWith(
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(color: Colors.black.withValues(alpha: 0.8), offset: const Offset(2, 2), blurRadius: 4),
                  ],
                ),
              ),
              12.height,  
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (data.details.releaseDate.isNotEmpty) Text(data.details.releaseDate.toString(), style: commonSecondaryTextStyle(size: 12)),
                    if(data.details.type != VideoType.video)...[
                      24.width,
                      if (data.details.language.isNotEmpty) const CachedImageWidget(url: Assets.iconsIcTranslate, height: 14, width: 14, color: iconColor),
                      6.width,
                      if (data.details.language.isNotEmpty) Text(data.details.language.capitalizeFirst!.validate(), style: commonSecondaryTextStyle(size: 12)),
                    ],
                    if(data.details.type != VideoType.tvshow)...[
                      24.width,
                      if (data.details.duration.isNotEmpty) const CachedImageWidget(url: Assets.iconsIcClock, height: 12, width: 12),
                      6.width,
                      if (data.details.duration.isNotEmpty) Text(data.details.duration.validate(), style: commonSecondaryTextStyle(size: 12)),
                    ],
                    24.width,
                    if (data.details.imdbRating != "") const CachedImageWidget(url: Assets.iconsIcStar, height: 10, width: 10),
                    6.width,
                    if (data.details.imdbRating != "") Text("${data.details.imdbRating} ${locale.value.iMDB}", style: commonSecondaryTextStyle(size: 12)),
                  ],
                ),
              ),
              if (data.details.description.isNotEmpty)
              16.height,
                Container(
                  width: Get.width * 0.45,
                  padding: const EdgeInsets.only(right: 5),
                  child: Text(
                    data.details.description,
                    style: commonSecondaryTextStyle(size: 14).copyWith(height: 1.4, color: Colors.white.withValues(alpha: 0.9)),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AppButton(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    color: appColorPrimary,
                    shapeBorder: RoundedRectangleBorder(
                      borderRadius: radius(6),
                      side: hasFocus ? BorderSide(color: white, width: 3, strokeAlign: BorderSide.strokeAlignOutside) : BorderSide.none,
                    ),
                    enabled: true,
                    onTap: onPosterTap,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const CachedImageWidget(url: Assets.iconsIcPlay, height: 14, width: 14),
                        12.width,
                        Text(locale.value.watchNow, style: appButtonTextStyleWhite.copyWith(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
