import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/components/cached_image_widget.dart';
import 'package:streamit_laravel/components/shimmer_widget.dart';
import 'package:streamit_laravel/generated/assets.dart';
import 'package:streamit_laravel/screens/coming_soon/coming_soon_controller.dart';
import 'package:streamit_laravel/screens/coming_soon/coming_soon_detail_screen.dart';
import 'package:streamit_laravel/screens/coming_soon/model/coming_soon_response.dart';
import 'package:streamit_laravel/screens/content/content_details_screen.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';
import 'package:streamit_laravel/screens/live_tv/live_tv_details/live_tv_details_screen.dart';
import 'package:streamit_laravel/screens/live_tv/model/live_tv_dashboard_response.dart';
import 'package:streamit_laravel/services/focus_sound_service.dart';
import 'package:streamit_laravel/utils/app_common.dart';
import 'package:streamit_laravel/utils/colors.dart';
import 'package:streamit_laravel/utils/constants.dart';

import '../../../main.dart';
import '../../../screens/dashboard/dashboard_controller.dart';
import '../../../screens/tv_show/trailer_video_player.dart';
import '../../../screens/tv_show/tv_show_detail_screen.dart';
import 'poster_card_controller.dart';

class PosterCardComponent extends StatelessWidget {
  final PosterDataModel contentDetail;
  final VideoData? videoData;
  final double? height;
  final double? width;

  String _getUrlTypeFromUrl(String url, String urlType) {
    if (urlType.isNotEmpty) {
      return urlType;
    }
    // Auto-detect URL type from URL
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      return 'youtube';
    } else if (url.contains('vimeo.com')) {
      return 'vimeo';
    } else if (url.contains('.m3u8')) {
      return 'hls';
    }
    return 'normal';
  }

  final bool isTop10;
  final bool isHorizontalList;
  final bool isSearch;
  final bool isLoading;
  final bool isTopChannel;
  final bool isPlayTrailer;
  final bool isForSearch;
  final VoidCallback? onTap;
  final ScrollController? control;
  final int? index;
  final Function(bool)? onFocusChange;
  final FocusNode? focusNode;
  final VoidCallback? saveSearchResults;
  final bool isLastIndex;
  final bool isSingleRow;
  final VoidCallback? onArrowUp;
  final VoidCallback? onArrowRight;
  final VoidCallback? onArrowLeft;
  final VoidCallback? onArrowDown;
  final String? categoryKey;
  final double heightFactor;
  final double widthFactor;

  const PosterCardComponent({
    super.key,
    required this.contentDetail,
    this.videoData,
    this.isTop10 = false,
    this.height,
    this.width,
    this.isHorizontalList = true,
    this.isLoading = false,
    this.isSearch = false,
    this.isTopChannel = false,
    this.isPlayTrailer = false,
    this.isForSearch = false,
    this.onTap,
    this.control,
    this.index,
    this.onFocusChange,
    this.focusNode,
    this.saveSearchResults,
    this.isLastIndex = false,
    this.isSingleRow = false,
    this.onArrowUp,
    this.onArrowRight,
    this.onArrowLeft,
    this.onArrowDown,
    this.categoryKey,
    this.heightFactor = 2.0,
    this.widthFactor = 1.5,
  });

  String get uniqueCategoryKey => categoryKey ?? 'unknown';

  PosterCardController get controller {
    final String tag =
        'poster_${contentDetail.id}_${index ?? 0}_$uniqueCategoryKey';
    return Get.isRegistered<PosterCardController>(tag: tag)
        ? Get.find<PosterCardController>(tag: tag)
        : Get.put(
            PosterCardController(
                contentDetail: contentDetail,
                videoData: videoData,
                isPlayTrailer: isPlayTrailer),
            tag: tag,
            permanent: true,
          );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        controller.hasFocus.value;
        return Focus(
          key: ValueKey(
              'focus_${contentDetail.id}_${index ?? 0}_$uniqueCategoryKey'),
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              if (onArrowLeft != null) {
                onArrowLeft!();
                return KeyEventResult.handled;
              } else if ((index ?? -1) == 0) {
                try {
                  final DashboardController controller =
                      Get.find<DashboardController>();
                  controller
                      .bottomNavItems[controller.selectedBottomNavIndex.value]
                      .focusNode
                      .requestFocus();
                } catch (_) {}
                return KeyEventResult.handled;
              }
            }
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.arrowUp) {
              onArrowUp?.call();
              return KeyEventResult.handled;
            }
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.arrowRight) {
              if (onArrowRight != null) {
                onArrowRight!();
                return KeyEventResult.handled;
              } else if (isHorizontalList && isLastIndex) {
                // No next index; ignore so nothing else handles
                return KeyEventResult.handled;
              }
            }
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.arrowDown) {
              if (onArrowDown != null) {
                onArrowDown!();
                return KeyEventResult.handled;
              } else {
                if (isHorizontalList && isSingleRow) {
                  return KeyEventResult.ignored;
                }
              }
            }
            if ((event is KeyDownEvent || event is KeyUpEvent) &&
                (event.logicalKey == LogicalKeyboardKey.select ||
                    event.logicalKey == LogicalKeyboardKey.enter)) {
              if (isLoading) return KeyEventResult.handled;
              saveSearchResults?.call();

              if (isTopChannel) {
                Get.to(
                  () => LiveShowDetailsScreen(),
                  arguments: ChannelModel(
                    id: contentDetail.id,
                    name: contentDetail.details.name,
                    serverUrl: contentDetail.details.trailerUrl ?? videoData?.url ?? '',
                    streamType: contentDetail.details.trailerUrlType ?? videoData?.urlType ?? '',
                    requiredPlanLevel: contentDetail.details.requiredPlanLevel,
                  ),
                );
                return KeyEventResult.handled;
              }

              if (contentDetail.details.releaseDate.isNotEmpty &&
                  isComingSoon(contentDetail.details.releaseDate)) {
                ComingSoonController comingSoonCont =
                    Get.put(ComingSoonController());
                Get.to(
                  () => ComingSoonDetailScreen(
                    comingSoonCont: comingSoonCont,
                    comingSoonData: ComingSoonModel.fromJson(
                        contentDetail.details.toListJson()),
                  ),
                );
              } else {
                if (contentDetail.details.type == VideoType.movie) {
                  Get.to(() => ContentDetailsScreen(),
                      arguments: contentDetail);
                } else if (contentDetail.details.type == VideoType.tvshow ||
                    contentDetail.details.type == VideoType.episode) {
                  Get.to(() => TVShowPreviewScreen(),
                      arguments: contentDetail);
                } else if (contentDetail.details.type == VideoType.video) {
                  Get.to(() => ContentDetailsScreen(),
                      arguments: contentDetail);
                }
              }
              return KeyEventResult.handled;
            }
            // Return ignored for unhandled keys to allow back navigation
            return KeyEventResult.ignored;
          },
          child: InkWell(
            focusNode: focusNode,
            canRequestFocus: true,
            onFocusChange: (value) {
              Scrollable.ensureVisible(
                context,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignmentPolicy:
                    ScrollPositionAlignmentPolicy.keepVisibleAtStart,
              );
              onFocusChange?.call(value);
              controller.setFocus(value);
              if (value) FocusSoundService.play();
            },
            onTap: onTap ??
                () {
                  if (isLoading) return;
                  saveSearchResults?.call();

                  if (isTopChannel) {
                    Get.to(
                      () => LiveShowDetailsScreen(),
                      arguments: ChannelModel(
                        id: contentDetail.id,
                        name: contentDetail.details.name,
                        serverUrl: contentDetail.details.trailerUrl ?? videoData?.url ?? '',
                        streamType: contentDetail.details.trailerUrlType ?? videoData?.urlType ?? '',
                        requiredPlanLevel: contentDetail.details.requiredPlanLevel,
                      ),
                    );
                    return;
                  }

                  if (contentDetail.details.releaseDate.isNotEmpty &&
                      isComingSoon(contentDetail.details.releaseDate)) {
                    ComingSoonController comingSoonCont =
                        Get.put(ComingSoonController());
                    Get.to(
                      () => ComingSoonDetailScreen(
                        comingSoonCont: comingSoonCont,
                        comingSoonData: ComingSoonModel.fromJson(
                            contentDetail.details.toListJson()),
                      ),
                    );
                  } else {
                    if (contentDetail.details.type == VideoType.movie) {
                      Get.to(() => ContentDetailsScreen(),
                          arguments: contentDetail);
                    } else if (contentDetail.details.type ==
                            VideoType.tvshow ||
                        contentDetail.details.type == VideoType.episode) {
                      Get.to(() => TVShowPreviewScreen(),
                          arguments: contentDetail);
                    } else if (contentDetail.details.type == VideoType.video) {
                      Get.to(() => ContentDetailsScreen(),
                          arguments: contentDetail);
                    }
                  }
                },
            child: Obx(
              () {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  height: isForSearch
                      ? (height ?? 150)
                      : (controller.hasFocus.value
                          ? (height ?? 150) * heightFactor
                          : (height ?? 150)),
                  width: isForSearch
                      ? (width ?? 110)
                      : (controller.hasFocus.value
                          ? (width ?? 110) * widthFactor
                          : (width ?? 110)),
                  transform: isForSearch
                      ? (controller.hasFocus.value
                          ? (Matrix4.identity()..scale(1.12))
                          : Matrix4.identity())
                      : Matrix4.identity(),
                  transformAlignment: Alignment.center,
                  margin: EdgeInsets.symmetric(
                      vertical: controller.hasFocus.value ? 0 : 8,
                      horizontal: 8),
                  decoration: boxDecorationDefault(
                    borderRadius: radius(8),
                    color: cardColor,
                    border: focusBorder(controller.hasFocus.value),
                    boxShadow: (controller.hasFocus.value &&
                            !controller.showTrailer.value)
                        ? [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 20,
                                spreadRadius: 5,
                                offset: const Offset(0, 10))
                          ]
                        : null,
                  ),
                  child: Stack(
                    children: [
                      if (isLoading)
                        ShimmerWidget(
                            height: double.infinity,
                            width: double.infinity,
                            radius: 8)
                      else if (controller.showTrailer.value && isPlayTrailer)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: TrailerPlayerWidget(
                            videoModel: ContentModel(
                              details: contentDetail.details,
                              downloadData: DownloadDataModel(
                                  downloadQualities: DownloadQualities()),
                              trailerData: (contentDetail
                                          .details.trailerUrl?.isNotEmpty ??
                                      false)
                                  ? [
                                      VideoData(
                                        url: contentDetail.details.trailerUrl ??
                                            '',
                                        urlType: _getUrlTypeFromUrl(
                                            contentDetail.details.trailerUrl ??
                                                '',
                                            contentDetail
                                                    .details.trailerUrlType ??
                                                ''),
                                      )
                                    ]
                                  : [],
                            ),
                            aspectRatio: (width ?? 110) / (height ?? 150),
                            onEnded: controller.onTrailerEnded,
                          ),
                        )
                      else
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedImageWidget(
                            url: contentDetail.posterImage,
                            height: double.infinity,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                          ),
                        ),
                      if (!controller.showTrailer.value)
                        if (contentDetail.details.access ==
                                MovieAccess.paidAccess ||
                            !contentDetail.details.hasContentAccess
                                .getBoolInt())
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              height: 20,
                              width: 20,
                              padding: const EdgeInsets.all(4),
                              decoration: boxDecorationDefault(
                                  shape: BoxShape.circle, color: yellowColor),
                              child: const CachedImageWidget(
                                  url: Assets.iconsIcVector),
                            ),
                          ),
                      if (!controller.showTrailer.value)
                        if (contentDetail.details.access ==
                            MovieAccess.payPerView)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: boxDecorationDefault(
                                  borderRadius: BorderRadius.circular(4),
                                  color: rentedColor),
                              child: Row(
                                spacing: 4,
                                children: [
                                  const CachedImageWidget(
                                      url: Assets.iconsIcRent,
                                      height: 8,
                                      width: 8,
                                      color: Colors.white),
                                  Text(
                                    contentDetail.details.hasContentAccess
                                            .getBoolInt()
                                        ? locale.value.rented
                                        : locale.value.rent,
                                    style: secondaryTextStyle(
                                        color: white, size: 10),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      if (controller.hasFocus.value &&
                          !controller.showTrailer.value)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.7),
                                  Colors.black.withValues(alpha: 0.95),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(contentDetail.details.name,
                                      style: boldTextStyle(),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 6),
                                  if (isHorizontalList &&
                                      (contentDetail.details.duration
                                              .toString()
                                              .isNotEmpty ||
                                          contentDetail.details.imdbRating
                                              .toString()
                                              .isNotEmpty))
                                    Flexible(
                                      child: Row(
                                        children: [
                                          if (contentDetail.details.imdbRating
                                              .toString()
                                              .isNotEmpty)
                                            Flexible(
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                    color: Colors.yellow
                                                        .withValues(alpha: 0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4)),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.star,
                                                        color: Colors.yellow,
                                                        size: 12),
                                                    const SizedBox(width: 4),
                                                    Flexible(
                                                      child: Text(
                                                        contentDetail
                                                            .details.imdbRating
                                                            .toString(),
                                                        style: boldTextStyle(
                                                            color:
                                                                Colors.yellow,
                                                            size: 11),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),

                                          // Runtime
                                          if (contentDetail.details.duration
                                              .toString()
                                              .isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                contentDetail.details.duration
                                                    .toString(),
                                                style: primaryTextStyle(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.8),
                                                    size: 11),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
