import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../main.dart';
import '../../../services/focus_sound_service.dart';
import '../../../utils/empty_error_state_widget.dart';
import '../tv_show_detail_controller.dart';

class SeasonsSection extends StatelessWidget {
  const SeasonsSection({super.key, required this.tvShowPreviewCont});

  final TvShowPreviewController tvShowPreviewCont;

  @override
  Widget build(BuildContext context) {
    return SnapHelperWidget(
      future: tvShowPreviewCont.getTvShowDetailsFuture.value,
      loadingWidget: Offstage(),
      errorBuilder: (error) {
        return NoDataWidget(
          titleTextStyle: secondaryTextStyle(color: white),
          subTitleTextStyle: primaryTextStyle(color: white),
          title: error,
          retryText: locale.value.reload,
          imageWidget: const ErrorStateWidget(),
          onRetry: () {
            tvShowPreviewCont.getTvShowDetail(showLoader: true);
          },
        ).visible(!tvShowPreviewCont.isLoading.value);
      },
      onSuccess: (data) {
        return AnimatedListView(
          listAnimationType: ListAnimationType.FadeIn,
          itemCount: tvShowPreviewCont.tvShowDetail.value.details.seasonList.length,
          itemBuilder: (context, index) {
            final FocusNode focusNode = (tvShowPreviewCont.seasonItemFocusNodes.length > index) ? tvShowPreviewCont.seasonItemFocusNodes[index] : FocusNode();
            final RxBool isFocused = false.obs;
            return Focus(
              focusNode: focusNode,
              onFocusChange: (p0) {
                isFocused(p0);
                if (p0) {
                  FocusSoundService.play();
                  tvShowPreviewCont.selectSeason(tvShowPreviewCont.tvShowDetail.value.details.seasonList[index]);
                  tvShowPreviewCont.page(1);
                  tvShowPreviewCont.currentSeason(index + 1);
                  tvShowPreviewCont.isLastPage(false);
                  tvShowPreviewCont.getEpisodeList();
                }
              },
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    final int total = tvShowPreviewCont.tvShowDetail.value.details.seasonList.length;

                    /// If only one season or at last index, block moving down
                    if (total <= 1 || index >= total - 1) {
                      return KeyEventResult.handled;
                    }

                    /// Otherwise allow default traversal to next item
                    return KeyEventResult.ignored;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    if (index > 0) {
                      try {
                        final nodes = tvShowPreviewCont.seasonItemFocusNodes;
                        if (nodes.length > index - 1) {
                          nodes[index - 1].requestFocus();
                          return KeyEventResult.handled;
                        }
                      } catch (_) {}
                      return KeyEventResult.ignored;
                    }
                    tvShowPreviewCont.selectedOption('seasons_episodes');
                    tvShowPreviewCont.pinOptionsToTop(true);
                    tvShowPreviewCont.optionSeasonsFocus.requestFocus();
                    return KeyEventResult.handled;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                    if (!tvShowPreviewCont.episodeSectionFocus.hasFocus &&
                        tvShowPreviewCont.seasonIdWiseEpisodeList[tvShowPreviewCont.selectSeason.value.seasonId] != null &&
                        tvShowPreviewCont.seasonIdWiseEpisodeList[tvShowPreviewCont.selectSeason.value.seasonId]!.isNotEmpty) {
                      tvShowPreviewCont.seasonIdWiseEpisodeList[tvShowPreviewCont.selectSeason.value.seasonId]!.first.itemFocusNode.requestFocus();
                      tvShowPreviewCont.scrollControl.animToTop();
                    }
                    return KeyEventResult.handled;
                  }

                  if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                    return KeyEventResult.handled;
                  }

                  if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: Obx(
                () => Container(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  margin: EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: tvShowPreviewCont.selectSeason.value.seasonId == tvShowPreviewCont.tvShowDetail.value.details.seasonList[index].seasonId
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: isFocused.value ? Border.all(color: Colors.white, width: 2) : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tvShowPreviewCont.tvShowDetail.value.details.seasonList[index].name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: primaryTextStyle(),
                      ).flexible(),
                      Text("${tvShowPreviewCont.tvShowDetail.value.details.seasonList[index].totalEpisode} episodes", style: secondaryTextStyle()),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
