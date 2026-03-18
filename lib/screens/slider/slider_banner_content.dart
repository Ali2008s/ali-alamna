import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:streamit_laravel/generated/assets.dart';
import 'package:streamit_laravel/main.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';
import 'package:streamit_laravel/utils/colors.dart';
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
    final bool isSportsNews = data.details.type == 'video' && data.details.id == 0;

    return Stack(
      children: [
        // ─── Full-size background image ──────────────────────────────────
        Positioned.fill(
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTap: onPosterTap,
                child: CachedImageWidget(
                  url: data.posterImage,
                  width: Get.width,
                  fit: BoxFit.cover,
                  height: Get.height * 0.62,
                  alignment: Alignment.center,
                ),
              ),
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

        // ─── Gradient overlay (bottom) ────────────────────────────────────
        IgnorePointer(
          ignoring: true,
          child: Container(
            height: Get.height * 0.62,
            width: Get.width,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.85),
                  Colors.black.withOpacity(0.97),
                ],
                stops: const [0.0, 0.35, 0.55, 0.78, 1.0],
              ),
            ),
          ),
        ),

        // ─── Side gradient (for readability) ─────────────────────────────
        IgnorePointer(
          ignoring: true,
          child: Container(
            height: Get.height * 0.62,
            width: Get.width,
            foregroundDecoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.85), Colors.transparent],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: const [0.0, 0.55],
              ),
            ),
          ),
        ),

        // ─── Live badge ───────────────────────────────────────────────────
        if (data.details.type == VideoType.liveTv)
          const Positioned(top: 14, left: 46, child: LiveCard()),

        // ─── Content info (bottom-left) ───────────────────────────────────
        Positioned(
          bottom: 16,
          left: 20,
          right: Get.width * 0.42,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Sports news badge
              if (isSportsNews)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    border: Border.all(color: Colors.red.withOpacity(0.6)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sports_soccer, color: Colors.red, size: 12),
                      SizedBox(width: 4),
                      Text('أخبار رياضية', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

              // Title
              Text(
                data.details.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                  shadows: [Shadow(color: Colors.black87, offset: Offset(1, 1), blurRadius: 4)],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),

              // Description (for news articles) - no "watch" button
              if (isSportsNews && data.details.description.isNotEmpty)
                Text(
                  data.details.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              else ...[
                // For non-news items: show metadata
                if (data.details.genres.isNotEmpty)
                  Text(
                    data.details.genres.join(' • '),
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                const SizedBox(height: 6),
                // Metadata row
                Row(
                  children: [
                    if (data.details.releaseDate.isNotEmpty)
                      Text(data.details.releaseDate, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    if (data.details.releaseDate.isNotEmpty && data.details.duration.isNotEmpty)
                      const Text(' • ', style: TextStyle(color: Colors.white30, fontSize: 12)),
                    if (data.details.duration.isNotEmpty)
                      Text(data.details.duration, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                // Watch button only for non-news items
                if (!isSportsNews)
                  GestureDetector(
                    onTap: onPosterTap,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: hasFocus ? Colors.white : appColorPrimary,
                        borderRadius: BorderRadius.circular(8),
                        border: hasFocus ? Border.all(color: Colors.white, width: 2) : null,
                        boxShadow: [
                          BoxShadow(
                            color: appColorPrimary.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CachedImageWidget(
                            url: Assets.iconsIcPlay,
                            height: 14,
                            width: 14,
                            color: hasFocus ? appColorPrimary : Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            locale.value.watchNow,
                            style: TextStyle(
                              color: hasFocus ? appColorPrimary : Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

