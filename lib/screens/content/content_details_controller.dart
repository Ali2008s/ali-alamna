import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/controllers/base_controller.dart';
import 'package:streamit_laravel/main.dart';
import 'package:streamit_laravel/network/core_api.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart' as video_model;
import 'package:streamit_laravel/screens/content/model/content_model.dart';
import 'package:streamit_laravel/utils/api_end_points.dart';
import 'package:streamit_laravel/utils/app_common.dart';
import 'package:streamit_laravel/utils/colors.dart';
import 'package:streamit_laravel/utils/common_base.dart';
import 'package:streamit_laravel/utils/constants.dart';
import 'package:streamit_laravel/services/subtitle_preload_service.dart';

class ContentDetailsController extends BaseController<ContentModel> with GetSingleTickerProviderStateMixin {
  late TabController tabController;

  Rx<Future<List<PosterDataModel>>> getEpisodeListFuture = Future(() => <PosterDataModel>[]).obs;

  RxList<PosterDataModel> episodeList = RxList();

  RxInt episodePage = 1.obs;

  RxBool isSubscriptionDialogOpen = false.obs;

  RxInt currentEpisodeIndex = (-1).obs;

  RxInt currentTab = 0.obs;

  RxBool isLastPage = false.obs;

  RxBool showShimmer = false.obs;

  RxBool isTrailer = true.obs;

  Rx<SeasonData> selectedSeason = SeasonData().obs;

  Rx<PosterDataModel> selectedEpisode = PosterDataModel(details: ContentData()).obs;

  PosterDataModel argumentData = PosterDataModel(details: ContentData());

  Rx<video_model.PosterDataModel> contentData = video_model.PosterDataModel(details: video_model.ContentData()).obs;

  @override
  void onInit() {
    init();
    if (Get.arguments is video_model.PosterDataModel) {
      contentData(Get.arguments);
      isTrailer(!isAlreadyStartedWatching(contentData.value.details.watchedDuration));
      if (contentData.value.details.type == VideoType.episode) {
        isTrailer(false);
      }
    }
    tabController = TabController(length: 2, vsync: this);
    super.onInit();
  }

  Future<void> init() async {
    if (Get.arguments is PosterDataModel) {
      argumentData = Get.arguments as PosterDataModel;
      update([argumentData]);
      if (argumentData.details.type == VideoType.episode) {
        isTrailer(false);
      }
      await getContentDetail(showLoader: false);
    } else if (Get.arguments is ContentData) {
      argumentData = PosterDataModel(details: (Get.arguments as ContentData));
      update([argumentData]);
      if (argumentData.details.type == VideoType.episode) {
        isTrailer(false);
      }
      await getContentDetail(showLoader: false);
    }
  }

  Future<void> getContentDetail({bool showLoader = true}) async {
    if (argumentData.entertainmentId < 0) return;
    showShimmer(!showLoader);
    await getContent(
      showLoader: showLoader,
      contentApiCall: () => CoreServiceApis.getContentDetails(
        contentId: argumentData.entertainmentId,
        type: argumentData.details.entertainmentType,
      ),
      onSuccess: (data) {
        if (data.details.type == VideoType.episode) {
          isTrailer(false);
          // Set the current episode as selected
          selectedEpisode(PosterDataModel(
            id: data.id,
            details: data.details,
            posterImage: data.details.thumbnailImage,
          ));
          // If it's an episode, load the episodes from the same season
          if (data.details.tvShowData != null && data.details.tvShowData!.id > 0) {
            selectedSeason(SeasonData(
              id: data.details.tvShowData!.id,
              seasonId: data.details.tvShowData!.seasonId,
              totalEpisode: data.details.tvShowData!.totalEpisode,
            ));
            if (selectedSeason.value.totalEpisode > 0) {
              getTvShowEpisodes();
            }
          }
        }
        if (content.value!.details.isSeasonAvailable) {
          setSeasonData(data.details.seasonList.first);
        }
        
        /// Preload subtitles in background when content details are fetched
        if (data.subtitleList.isNotEmpty) {
          log("[SUBTITLE] Content Details API success - triggering subtitle preload: content_id=${data.id}, subtitle_count=${data.subtitleList.length}");
          SubtitlePreloadService().preloadSubtitles(data).catchError((error) {
            log("[SUBTITLE] Background subtitle preload failed: content_id=${data.id}, error=$error");
          });
        } else {
          log("[SUBTITLE] Content Details API success - no subtitles available: content_id=${data.id}");
        }
      },
    ).whenComplete(() => showShimmer(false));
  }

  //endregion

  void playNextEpisode(PosterDataModel episode, {bool isFromPlayer = false}) {
    if (episode.id != selectedEpisode.value.id) {
      onSubscriptionLoginCheck(
        callBack: () async {
          if (isLoggedIn.isTrue && (episode.details.hasContentAccess.getBoolInt())) {
            selectedEpisode(episode);
            currentEpisodeIndex(episodeList.indexWhere((element) => element.id == episode.id));
            getEpisodeContentData(episodeData: episode, isFromPlayer: isFromPlayer);
          } else if ((episode.details.access == MovieAccess.payPerView) && !episode.details.hasContentAccess.getBoolInt()) {
            isSubscriptionDialogOpen(true);
            await showSubscriptionDialog(title: locale.value.rentRequired, msg: locale.value.rentToWatch, color: rentedColor);
            isSubscriptionDialogOpen(false);
          }
        },
        videoAccess: '',
      );
    } else {
      log('+-+-+-+-+-+ Episode is the same, skipping');
    }
  }

  Future<void> getEpisodeContentData({bool showLoader = true, required PosterDataModel episodeData, bool isFromPlayer = false}) async {
    if (episodeData.id < 0) {
      log('+-+-+-+-+-+ Invalid episode ID, returning');
      return;
    }
    if (isLoading.value) {
      log('+-+-+-+-+-+ Already loading, returning');
      return;
    }
    setLoading(showLoader);

    await CoreServiceApis.getContentDetails(
      contentId: episodeData.id,
      type: episodeData.details.type,
      tvShowId: selectedSeason.value.id,
      seasonId: selectedSeason.value.seasonId,
    ).then(
      (value) {
        if (isFromPlayer) {
          content(value);
          isTrailer(false);
          selectedEpisode(PosterDataModel(id: value.id, details: value.details, posterImage: value.details.thumbnailImage));

          final videoUrl = value.videoQualities.isNotEmpty ? value.videoQualities.first.url : "";
          final urlType = value.videoQualities.isNotEmpty ? value.videoQualities.first.urlType : "url";

          LiveStream().emit(
            changeVideoInPodPlayer,
            [
              videoUrl, // [0] - Video URL
              false, // [1] - isQuality (false = changing to new video)
              urlType, // [2] - URL type (url, hls, etc.)
              VideoType.episode, // [3] - video type
              value, // [4] - ContentModel
            ],
          );
        }
        
        /// Preload subtitles in background for episode content
        if (value.subtitleList.isNotEmpty) {
          log("[SUBTITLE] Episode Content Details API success - triggering subtitle preload: episode_id=${value.id}, subtitle_count=${value.subtitleList.length}");
          SubtitlePreloadService().preloadSubtitles(value).catchError((error) {
            log("[SUBTITLE] Background subtitle preload failed for episode: episode_id=${value.id}, error=$error");
          });
        } else {
          log("[SUBTITLE] Episode Content Details API success - no subtitles available: episode_id=${value.id}");
        }
      },
    ).whenComplete(() => setLoading(false));
  }

  void handleNextEpisode() async {
    if (!isLastPage.value) {
      episodePage++;
      await getTvShowEpisodes();
    }
  }

  Future<void> getTvShowEpisodes() async {
    await getEpisodeListFuture(
      CoreServiceApis.getEpisodesList(
        page: episodePage.value,
        showId: selectedSeason.value.id,
        seasonId: selectedSeason.value.seasonId,
        episodeList: episodeList,
        lastPageCallBack: (p0) {
          isLastPage(p0);
        },
      ),
    ).catchError((e) {
      throw e;
    }).whenComplete(() {
      setLoading(false);
      if (selectedEpisode.value.id > 0 && episodeList.isNotEmpty) {
        final index = episodeList.indexWhere((element) => element.id == selectedEpisode.value.id);
        if (index >= 0) {
          currentEpisodeIndex(index);
        }
      }
    });
  }

  void setSeasonData(SeasonData newSeason) {
    episodePage(1);
    selectedSeason(newSeason);
    if (selectedSeason.value.totalEpisode > 0) getTvShowEpisodes();
  }

  /// Get current episode index dynamically
  int getCurrentEpisodeIndex() {
    int currentIndex = -1;
    final model = content.value;

    if (model == null) return currentIndex;

    if (model.isEpisode && episodeList.isNotEmpty) {
      currentIndex = episodeList.indexWhere((element) => element.id == model.id);
    }

    if (currentIndex == -1 && selectedEpisode.value.id > 0) {
      currentIndex = episodeList.indexWhere((element) => element.id == selectedEpisode.value.id);
    }

    if (currentIndex == -1) {
      currentIndex = currentEpisodeIndex.value;
    }

    return currentIndex;
  }

  /// Handle watch now button press
  void handleWatchNow() {
    final model = content.value;
    if (model == null) return;

    onSubscriptionLoginCheck(
      callBack: () {
        isTrailer(false);
        LiveStream().emit(
          mOnWatchVideo,
          [
            model.videoQualities.isNotEmpty ? model.videoQualities.first.url : "",
            false,
            model.isDefaultQualityAvailable ? model.defaultQuality.urlType : (model.videoQualities.isNotEmpty ? model.videoQualities.first.urlType : ""),
            VideoType.movie,
            model,
            model.details.watchedDuration,
          ],
        );
      },
      videoAccess: model.details.access,
    );
  }

  /// Handle watching next episode
  void onWatchNextEpisode() {
    // Get current episode index
    final currentIndex = getCurrentEpisodeIndex();

    if (episodeList.isNotEmpty && currentIndex >= 0 && currentIndex < episodeList.length - 1) {
      final nextEpisode = episodeList[currentIndex + 1];
      playNextEpisode(nextEpisode, isFromPlayer: true);
    }
  }

  Future<void> watchListContent(int id) async {
    if (isLoading.isTrue) return;
    isLoading(true);
    final int isWatchList = content.value!.details.isInWatchList.getBoolInt() ? 0 : 1;
    content.value?.details.isInWatchList = isWatchList.getBoolInt() ? 1 : 0;
    hideKeyBoardWithoutContext();
    isLoading(false);
    if (isWatchList == 1) {
      CoreServiceApis.saveWatchList(
        request: {
          "entertainment_id": id,
          if (selectedAccountProfile.value.id != 0) ApiRequestKeys.profileIdKey: selectedAccountProfile.value.id,
          ApiRequestKeys.typeKey: content.value?.details.type,
        },
      ).then((value) async {
        successSnackBar(locale.value.addedToWatchList);
        await getContentDetail();
      }).catchError((e) {
        content.value?.details.isInWatchList = 0;
      }).whenComplete(() {
        setLoading(false);
      });
    } else {
      content.value?.details.isInWatchList = 0;
      await CoreServiceApis.deleteFromWatchlist(idList: [id]).then((value) async {
        await getContentDetail();
        successSnackBar(locale.value.removedFromWatchList);
      }).catchError((e) {
        content.value?.details.isInWatchList = 1;
      }).whenComplete(() {
        setLoading(false);
      });
    }
  }
}