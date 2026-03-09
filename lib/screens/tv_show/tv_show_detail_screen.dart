import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/screens/tv_show/components/synopsis_component.dart';
import 'package:streamit_laravel/screens/tv_show/components/trailers_clips_item_component.dart';
import 'package:streamit_laravel/screens/tv_show/trailer_video_player.dart';
import 'package:streamit_laravel/utils/constants.dart';

import '../../components/app_scaffold.dart';
import '../../utils/animatedscroll_view_widget.dart';
import '../../utils/colors.dart';
import '../content/content_details_screen.dart';
import 'components/episode_section.dart';
import 'components/seasons_section.dart';
import 'components/tabs_item_component.dart';
import 'components/tv_show_detail_shimmer.dart';
import 'tv_show_detail_controller.dart';

class TVShowPreviewScreen extends StatelessWidget {
  TVShowPreviewScreen({super.key});

  final TvShowPreviewController tvShowPreviewCont = Get.put(TvShowPreviewController());

  @override
  Widget build(BuildContext context) {
    /// Ensure options are not pinned after hot reload if none are focused
    afterBuildCreated(() {
      if (!(tvShowPreviewCont.optionSeasonsFocus.hasFocus ||
          tvShowPreviewCont.optionMoreLikeFocus.hasFocus ||
          tvShowPreviewCont.optionClipsFocus.hasFocus)) {
        tvShowPreviewCont.pinOptionsToTop(false);
      }
    });
    return AppScaffoldNew(
      hasLeadingWidget: false,
      hideAppBar: true,
      topBarBgColor: canvasColor,
      scaffoldBackgroundColor: black,
      body: Obx(() {
        final bool isLoading = tvShowPreviewCont.isLoading.value;
        final bool pinned = tvShowPreviewCont.pinOptionsToTop.value && !isLoading;
        final String selectedOption = tvShowPreviewCont.selectedOption.value;
        final double heroHeight = isLoading ? Get.height : (pinned ? 0 : Get.height);

        return Column(
          children: [
            SizedBox(
              height: heroHeight,
              width: Get.width,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (isLoading)
                    const TvShowHeroBackdropShimmer()
                  else
                    Positioned.fill(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Obx(() => TrailerPlayerWidget(
                              key: tvShowPreviewCont.trailerPlayerKey,
                              videoModel: tvShowPreviewCont.trailerData.value,
                              onEnded: tvShowPreviewCont.onTrailerEnded)),
                          /* Obx(() => tvShowPreviewCont.showPosterOverlay.value
                              ? CachedImageWidget(
                                  url: tvShowPreviewCont.tvShowDetail.value.details.thumbnailImage, fit: BoxFit.cover)
                              : const Offstage()), */
                        ],
                      ),
                    ),

                  /// Left shadow for synopsis readability
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: Get.width * 0.6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Colors.black.withValues(alpha: 0.85), Colors.black.withValues(alpha: 0.0)],
                        ),
                      ),
                    ),
                  ),

                  /// Left panel synopsis + Watch Now
                  isLoading
                      ? const TvShowSynopsisShimmer()
                      : TvShowSynopsisComponent(tvShowPreviewCont: tvShowPreviewCont),

                  // Options row overlaid at bottom when not pinned
                  if (!pinned)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: isLoading
                          ? const TvShowOptionsRowShimmer(padding: EdgeInsets.symmetric(horizontal: 24))
                          : Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                              child: Row(
                                children: [
                                  TabsItemComponent(
                                    label: 'Seasons & Episodes',
                                    focusNode: tvShowPreviewCont.optionSeasonsFocus,
                                    isFocused: tvShowPreviewCont.isOptionSeasonsFocused,
                                    onFocusChange: tvShowPreviewCont.handleSeasonsFocusChange,
                                    onKeyEvent: tvShowPreviewCont.handleSeasonsKey,
                                    onTap: tvShowPreviewCont.handleSeasonsTap,
                                  ),
                                  16.width,
                                  TabsItemComponent(
                                    label: 'Trailers & Clips',
                                    focusNode: tvShowPreviewCont.optionClipsFocus,
                                    isFocused: tvShowPreviewCont.isOptionClipsFocused,
                                    onFocusChange: tvShowPreviewCont.handleClipsFocusChange,
                                    onKeyEvent: tvShowPreviewCont.handleClipsKey,
                                    onTap: tvShowPreviewCont.handleClipsTap,
                                  ),
                                  16.width,
                                  TabsItemComponent(
                                    label: 'More Like This',
                                    focusNode: tvShowPreviewCont.optionMoreLikeFocus,
                                    isFocused: tvShowPreviewCont.isOptionMoreLikeFocused,
                                    onFocusChange: tvShowPreviewCont.handleMoreLikeFocusChange,
                                    onKeyEvent: tvShowPreviewCont.handleMoreLikeKey,
                                    onTap: tvShowPreviewCont.handleMoreLikeTap,
                                  ),
                                ],
                              ),
                            ),
                    ),
                ],
              ),
            ),
            if (!isLoading)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (pinned)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Row(
                          children: [
                            TabsItemComponent(
                              label: 'Seasons & Episodes',
                              focusNode: tvShowPreviewCont.optionSeasonsFocus,
                              isFocused: tvShowPreviewCont.isOptionSeasonsFocused,
                              onFocusChange: tvShowPreviewCont.handleSeasonsFocusChange,
                              onKeyEvent: tvShowPreviewCont.handleSeasonsKey,
                              onTap: tvShowPreviewCont.handleSeasonsTap,
                            ),
                            16.width,
                            TabsItemComponent(
                              label: 'Trailers & Clips',
                              focusNode: tvShowPreviewCont.optionClipsFocus,
                              isFocused: tvShowPreviewCont.isOptionClipsFocused,
                              onFocusChange: tvShowPreviewCont.handleClipsFocusChange,
                              onKeyEvent: tvShowPreviewCont.handleClipsKey,
                              onTap: tvShowPreviewCont.handleClipsTap,
                            ),
                            16.width,
                            TabsItemComponent(
                              label: 'More Like This',
                              focusNode: tvShowPreviewCont.optionMoreLikeFocus,
                              isFocused: tvShowPreviewCont.isOptionMoreLikeFocused,
                              onFocusChange: tvShowPreviewCont.handleMoreLikeFocusChange,
                              onKeyEvent: tvShowPreviewCont.handleMoreLikeKey,
                              onTap: tvShowPreviewCont.handleMoreLikeTap,
                            ),
                          ],
                        ),
                      ),
                    if (pinned) const Divider(height: 1, thickness: 1, color: Colors.white24),
                    16.height,
                    Expanded(child: _buildLoadedBottomContent(selectedOption)),
                  ],
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildLoadedBottomContent(String selectedOption) {
    if (selectedOption == 'clips') {
      final model = tvShowPreviewCont.tvShowDetail.value;
      final clips = model.trailerData;
      tvShowPreviewCont.prepareClipsFocus(clips.length);
      if (clips.isEmpty) {
        return Center(child: Text('No clips', style: primaryTextStyle(color: white)));
      }

      final double cardWidth = (Get.width / 6.5).clamp(180.0, 320.0);
      final double cardHeight = cardWidth * 9 / 16;

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: List.generate(clips.length, (i) {
            final item = clips[i];
            final String rawTitle = item.title;
            final String title = (rawTitle.toLowerCase() == 'default trailer') ? 'Trailer' : rawTitle;
            final FocusNode cardFocus = tvShowPreviewCont.clipsFocusNodes[i];
            return TrailersClipsItemComponent(
              key: ValueKey('trailer_clip_$i'),
              item: item,
              title: title,
              width: cardWidth,
              height: cardHeight,
              focusNode: cardFocus,
              controller: tvShowPreviewCont,
            );
          }),
        ),
      );
    }

    if (selectedOption == 'more_like') {
      final list = tvShowPreviewCont.tvShowDetail.value.suggestedContent;
      if (list.isEmpty) {
        return Center(child: Text('No suggestions', style: primaryTextStyle(color: white)));
      }

      return CustomAppScrollingWidget(
        paddingLeft: 24,
        paddingRight: 24,
        paddingBottom: 24,
        spacing: 12,
        runSpacing: 12,
        posterHeight: 150 * 1.2,
        posterWidth: (Get.width / 8.8) * 1.2,
        isLoading: false,
        isLastPage: true,
        itemList: list,
        onNextPage: () async {},
        onSwipeRefresh: () async {},
        onTap: (posterDet) {
          if (posterDet.details.type == VideoType.tvshow || posterDet.details.type == VideoType.episode) {
            Get.off(() => TVShowPreviewScreen(), arguments: posterDet, preventDuplicates: false);
          } else {
            Get.to(() => ContentDetailsScreen(), arguments: posterDet);
          }
        },
        onUpFromItems: () {
          tvShowPreviewCont.optionMoreLikeFocus.requestFocus();
        },
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
            width: Get.width * 0.30,
            color: Colors.black.withValues(alpha: 0.4),
            child: SeasonsSection(tvShowPreviewCont: tvShowPreviewCont)),
        Expanded(child: EpisodesSection(tvShowPreviewCont: tvShowPreviewCont)),
      ],
    );
  }
}
