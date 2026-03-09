import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';

import '../../../components/cached_image_widget.dart';
import '../../../generated/assets.dart';
import '../../../main.dart';
import '../../../services/focus_sound_service.dart';
import '../../../utils/app_common.dart';
import '../../../utils/colors.dart';
import '../../../utils/common_base.dart';
import '../../../utils/constants.dart';
import '../../../utils/empty_error_state_widget.dart';
import '../../content/content_details_screen.dart';
import '../tv_show_detail_controller.dart';

class EpisodesSection extends StatelessWidget {
  const EpisodesSection({
    super.key,
    required this.tvShowPreviewCont,
  });

  final TvShowPreviewController tvShowPreviewCont;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SingleChildScrollView(
        scrollDirection: Axis.vertical,
        controller: tvShowPreviewCont.scrollControl,
        child: SnapHelperWidget(
          future: tvShowPreviewCont.getEpisodeListFuture.value,
          loadingWidget: const Offstage(),
          errorBuilder: (error) {
            return NoDataWidget(
              titleTextStyle: secondaryTextStyle(color: white),
              subTitleTextStyle: primaryTextStyle(color: white),
              title: error,
              retryText: locale.value.reload,
              imageWidget: const ErrorStateWidget(),
              onRetry: () {
                tvShowPreviewCont.getTvShowDetail();
              },
            );
          },
          onSuccess: (data) {
            return tvShowPreviewCont.isLoadingEpisode.value
                ? const SizedBox.shrink()
                : Obx(
                    () {
                      final episodeList = tvShowPreviewCont.seasonIdWiseEpisodeList[tvShowPreviewCont.selectSeason.value.seasonId];
                      if (episodeList == null || episodeList.isEmpty) {
                        return emptyWidget ?? const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          children: List.generate(episodeList.length, (index) {
                            PosterDataModel ep = episodeList[index];
                            final RxBool isFocused = false.obs;
                            final GlobalKey itemKey = GlobalKey();
                            return Focus(
                              canRequestFocus: true,
                              focusNode: ep.itemFocusNode,
                              onFocusChange: (value) {
                                isFocused(value);
                                if (value) {
                                  FocusSoundService.play();
                                  try {
                                    final ctx = itemKey.currentContext;
                                    if (ctx != null) {
                                      final int totalEpisodes = tvShowPreviewCont.seasonIdWiseEpisodeList[tvShowPreviewCont.selectSeason.value.seasonId]?.length ?? 0;
                                      final bool isLast = index >= totalEpisodes - 1 && totalEpisodes > 0;
                                      Scrollable.ensureVisible(
                                        ctx,
                                        alignment: isLast ? 1.0 : 0.4,
                                        duration: const Duration(milliseconds: 180),
                                        curve: Curves.easeOutCubic,
                                        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
                                      );
                                    }
                                  } catch (_) {}
                                }
                              },
                              onKeyEvent: (node, event) {
                                if (event is KeyDownEvent) {
                                  if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                                    /// If first episode, fallback to options/top area; else move to previous item explicitly
                                    if (index == 0) {
                                      tvShowPreviewCont.optionSeasonsFocus.requestFocus();
                                      return KeyEventResult.handled;
                                    }
                                    try {
                                      final list = tvShowPreviewCont.seasonIdWiseEpisodeList[tvShowPreviewCont.selectSeason.value.seasonId];
                                      list?[index - 1].itemFocusNode.requestFocus();
                                      return KeyEventResult.handled;
                                    } catch (_) {}
                                    return KeyEventResult.ignored;
                                  }
                                  if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                                    /// If last episode, block moving down; else move to next item explicitly
                                    final int totalEpisodes = tvShowPreviewCont.seasonIdWiseEpisodeList[tvShowPreviewCont.selectSeason.value.seasonId]?.length ?? 0;
                                    if (index >= totalEpisodes - 1) {
                                      return KeyEventResult.handled;
                                    }
                                    try {
                                      final list = tvShowPreviewCont.seasonIdWiseEpisodeList[tvShowPreviewCont.selectSeason.value.seasonId];
                                      list?[index + 1].itemFocusNode.requestFocus();
                                      return KeyEventResult.handled;
                                    } catch (_) {}
                                    return KeyEventResult.ignored;
                                  }
                                  if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                                    tvShowPreviewCont.focusSeasonsList();
                                    return KeyEventResult.handled;
                                  }

                                  if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                                    return KeyEventResult.handled;
                                  }

                                  if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
                                    onSubscriptionLoginCheck(
                                      title: tvShowPreviewCont.tvShowDetail.value.details.name,
                                      planLevel: tvShowPreviewCont.tvShowDetail.value.details.requiredPlanLevel,
                                      videoAccess: tvShowPreviewCont.tvShowDetail.value.details.access,
                                      callBack: () {
                                        doIfLogin(onLoggedIn: () {
                                          if ((ep.details.access == MovieAccess.payPerView) && !ep.details.hasContentAccess.getBoolInt()) {
                                            showSubscriptionDialog(title: locale.value.rentRequired, msg: locale.value.rentToWatch, color: rentedColor);
                                          } else if (((ep.details.access == MovieAccess.paidAccess) && isMoviePaid(requiredPlanLevel: ep.details.requiredPlanLevel)) || !ep.details.isDeviceSupported.getBoolInt()) {
                                            showSubscriptionDialog(title: locale.value.subscriptionRequired, msg: locale.value.pleaseSubscribeOrUpgrade);
                                          } else {
                                            tvShowPreviewCont.currentEpisodeIndex(index);

                                            /// Navigate to Content Details to fetch episode content and play
                                            Get.to(() => ContentDetailsScreen(), arguments: ep);
                                          }
                                        });
                                      },
                                    );
                                    return KeyEventResult.handled;
                                  }
                                }
                                return KeyEventResult.ignored;
                              },
                              child: Container(
                                key: itemKey,
                                margin: const EdgeInsets.only(bottom: 24),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 160,
                                      height: 90,
                                      decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(8)),
                                      child: Obx(
                                        () => AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          curve: Curves.easeOut,
                                          transform: Matrix4.identity()..scale(isFocused.value ? 1.05 : 1.0),
                                          height: 120,
                                          decoration: BoxDecoration(
                                            borderRadius: radius(8),
                                            border: focusBorder(isFocused.value),
                                            boxShadow: isFocused.value ? [BoxShadow(color: white.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4), spreadRadius: 2)] : null,
                                          ),
                                          child: Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius: radius(6),
                                                child: Stack(
                                                  fit: StackFit.expand,
                                                  children: [
                                                    CachedImageWidget(url: ep.posterImage, fit: BoxFit.cover),
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          begin: Alignment.topCenter,
                                                          end: Alignment.bottomCenter,
                                                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                                                        ),
                                                      ),
                                                    ),
                                                    if (ep.details.access == MovieAccess.payPerView)
                                                      Positioned(
                                                        top: 4,
                                                        left: 5,
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                          decoration: boxDecorationDefault(borderRadius: BorderRadius.circular(4), color: rentedColor),
                                                          child: Row(
                                                            spacing: 4,
                                                            children: [
                                                              const CachedImageWidget(url: Assets.iconsIcRent, height: 8, width: 8, color: Colors.white),
                                                              Text(
                                                                ep.details.hasContentAccess.getBoolInt() ? locale.value.rented : locale.value.rent,
                                                                style: secondaryTextStyle(color: white, size: 10),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      )
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(ep.details.name, style: TextStyle(color: Colors.white, fontSize: 16)),
                                          6.height,
                                          /// Duration
                                          if (formatEpisodeDuration(ep.details.duration).isNotEmpty)
                                            Text(formatEpisodeDuration(ep.details.duration), style: TextStyle(color: Colors.white70, fontSize: 12)),
                                          if (formatEpisodeDuration(ep.details.duration).isNotEmpty) const SizedBox(height: 6),
                                          /// Short Description
                                          if ((ep.details.shortDescription ?? '').trim().isNotEmpty)
                                            Text(ep.details.shortDescription ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white70, fontSize: 14)),
                                          if ((ep.details.shortDescription ?? '').trim().isNotEmpty) const SizedBox(height: 6),
                                          /// Release date only (after title, duration, short desc)
                                          if (ep.details.releaseDate.trim().isNotEmpty) Text(ep.details.releaseDate, style: TextStyle(color: Colors.white54, fontSize: 12)),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      );
                    },
                  );
          },
        ),
      ),
    );
  }

  EmptyStateWidget? get emptyWidget => tvShowPreviewCont.seasonIdWiseEpisodeList[tvShowPreviewCont.selectSeason.value.seasonId] != null &&
          tvShowPreviewCont.seasonIdWiseEpisodeList[tvShowPreviewCont.selectSeason.value.seasonId]!.isEmpty
      ? EmptyStateWidget()
      : null;
}
