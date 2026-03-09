import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/screens/content/content_details_controller.dart';
import 'package:streamit_laravel/utils/colors.dart';

import '../../components/app_scaffold.dart';
import '../../utils/common_base.dart';
import '../../video_players/video_player.dart';

class ContentDetailsScreen extends StatelessWidget {
  final bool isFromContinueWatch;

  const ContentDetailsScreen({super.key, this.isFromContinueWatch = false});

  @override
  Widget build(BuildContext context) {
    final contentDetailsController = Get.put(ContentDetailsController());

    return AppScaffoldNew(
      hasLeadingWidget: false,
      hideAppBar: true,
      isLoading: contentDetailsController.isLoading,
      scaffoldBackgroundColor: black,
      topBarBgColor: appScreenBackgroundDark,
      body: RefreshIndicator(
        color: appColorPrimary,
        onRefresh: () async {
          return await contentDetailsController.getContentDetail();
        },
        child: Obx(() {
          final model = contentDetailsController.content.value;
          if (model == null || model.id == -1) {
            return const SizedBox();
          }

          final currentIndex = contentDetailsController.getCurrentEpisodeIndex();
          final hasNext = contentDetailsController.episodeList.isNotEmpty && currentIndex >= 0 && currentIndex < contentDetailsController.episodeList.length - 1;

          return VideoPlayersComponent(
            videoModel: model,
            videoData: getVideoPlayerResp(model.toContentJson()),
            isTrailer: contentDetailsController.isTrailer.value && !isFromContinueWatch,
            hasNextEpisode: hasNext,
            nextEpisodeThumbnailImage: hasNext ? contentDetailsController.episodeList[currentIndex + 1].posterImage : "",
            nextEpisodeIndex: hasNext ? currentIndex + 1 : 0,
            nextEpisodeTitle: hasNext ? contentDetailsController.episodeList[currentIndex + 1].details.name : "",
            onWatchNow: () {
              contentDetailsController.handleWatchNow();
            },
            onWatchNextEpisode: () {
              contentDetailsController.onWatchNextEpisode();
            },
          );
        }),
      ),
    );
  }
}
