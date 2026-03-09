import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../components/app_scaffold.dart';
import '../../utils/colors.dart';
import '../../video_players/video_player.dart';
import '../../utils/common_base.dart';
import 'tv_show_detail_controller.dart';

class EpisodePlayerScreen extends StatelessWidget {
  EpisodePlayerScreen({super.key});

  final TvShowPreviewController tvShowPreviewCont = Get.put(TvShowPreviewController());

  @override
  Widget build(BuildContext context) {
    return AppScaffoldNew(
      hasLeadingWidget: false,
      hideAppBar: true,
      topBarBgColor: canvasColor,
      scaffoldBackgroundColor: black,
      body: Stack(
        children: [
          Obx(
            () {
              return VideoPlayersComponent(
                isTrailer: false,
                videoModel: tvShowPreviewCont.showData.value,
                videoData: getVideoPlayerResp(tvShowPreviewCont.showData.value.toContentJson()),

                //  Get the list of episodes for the selected season safely
                hasNextEpisode:
                    tvShowPreviewCont.seasonIdWiseEpisodeList[tvShowPreviewCont.selectSeason.value.seasonId] != null &&
                        tvShowPreviewCont.currentEpisodeIndex.value <
                            tvShowPreviewCont
                                    .seasonIdWiseEpisodeList[tvShowPreviewCont.selectSeason.value.seasonId]!.length -
                                1,

                nextEpisodeThumbnailImage:
                    (tvShowPreviewCont.seasonIdWiseEpisodeList[tvShowPreviewCont.selectSeason.value.seasonId] != null &&
                            tvShowPreviewCont.currentEpisodeIndex.value <
                                tvShowPreviewCont
                                        .seasonIdWiseEpisodeList[tvShowPreviewCont.selectSeason.value.seasonId]!
                                        .length -
                                    1)
                        ? tvShowPreviewCont
                            .seasonIdWiseEpisodeList[tvShowPreviewCont.selectSeason.value.seasonId]![
                                tvShowPreviewCont.currentEpisodeIndex.value + 1]
                            .posterImage
                        : "",

                nextEpisodeIndex:
                    (tvShowPreviewCont.seasonIdWiseEpisodeList[tvShowPreviewCont.selectSeason.value.seasonId] != null &&
                            tvShowPreviewCont.currentEpisodeIndex.value <
                                tvShowPreviewCont
                                        .seasonIdWiseEpisodeList[tvShowPreviewCont.selectSeason.value.seasonId]!
                                        .length -
                                    1)
                        ? tvShowPreviewCont.currentEpisodeIndex.value + 1
                        : 0,

                nextEpisodeTitle:
                    (tvShowPreviewCont.seasonIdWiseEpisodeList[tvShowPreviewCont.selectSeason.value.seasonId] != null &&
                            tvShowPreviewCont.currentEpisodeIndex.value <
                                tvShowPreviewCont
                                        .seasonIdWiseEpisodeList[tvShowPreviewCont.selectSeason.value.seasonId]!
                                        .length -
                                    1)
                        ? tvShowPreviewCont
                            .seasonIdWiseEpisodeList[tvShowPreviewCont.selectSeason.value.seasonId]![
                                tvShowPreviewCont.currentEpisodeIndex.value + 1]
                            .details.name
                        : "",

                //  Watch Now pressed
                // onWatchNow: () {
                //   tvShowPreviewCont.isTrailer(false);
                //   final episodeList =
                //       tvShowPreviewCont.seasonIdWiseEpisodeList[tvShowPreviewCont.selectSeason.value.seasonId] ??
                //           <EpisodeModel>[].obs;
                //   if (tvShowPreviewCont.currentEpisodeIndex.value < episodeList.length - 1) {
                //     tvShowPreviewCont.currentEpisodeIndex.value++;
                //     tvShowPreviewCont.playNextEpisode(episodeList[tvShowPreviewCont.currentEpisodeIndex.value]);
                //   }
                // },

                //  Watch Next Episode pressed
                onWatchNextEpisode: () {
                  onWatchNextEpisode();
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void onWatchNextEpisode() {
    if (tvShowPreviewCont.seasonIdWiseEpisodeList[tvShowPreviewCont.selectSeason.value.seasonId] != null &&
        tvShowPreviewCont.currentEpisodeIndex.value <
            tvShowPreviewCont.seasonIdWiseEpisodeList[tvShowPreviewCont.selectSeason.value.seasonId]!.length) {
      tvShowPreviewCont.currentEpisodeIndex.value++;
      tvShowPreviewCont.playNextEpisode(tvShowPreviewCont.seasonIdWiseEpisodeList[
          tvShowPreviewCont.selectSeason.value.seasonId]![tvShowPreviewCont.currentEpisodeIndex.value]);
    }
  }
}
