import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/services/focus_sound_service.dart';
import 'package:streamit_laravel/utils/common_base.dart';
import '../../network/core_api.dart';
import '../../main.dart';
import '../../utils/app_common.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import 'episode_video_player.dart';
import 'trailer_video_player.dart';
import '../content/model/content_model.dart';
import '../content/content_details_screen.dart';

class TvShowPreviewController extends GetxController {
  RxBool isLoading = false.obs;
  RxBool isLoadingEpisode = false.obs;
  RxBool displaySkipButton = false.obs;
  RxBool isLastPage = false.obs;
  RxBool isTrailer = true.obs;

  Rx<Future<ContentModel>> getTvShowDetailsFuture = Future(() =>
          ContentModel(details: ContentData(), downloadData: DownloadDataModel(downloadQualities: DownloadQualities())))
      .obs;
  Rx<Future<List<PosterDataModel>>> getEpisodeListFuture = Future(() => <PosterDataModel>[]).obs;

  Rx<ContentModel> tvShowDetail =
      ContentModel(details: ContentData(), downloadData: DownloadDataModel(downloadQualities: DownloadQualities())).obs;
  Rx<ContentModel> showData =
      ContentModel(details: ContentData(), downloadData: DownloadDataModel(downloadQualities: DownloadQualities())).obs;
  Rx<ContentModel> trailerData =
      ContentModel(details: ContentData(), downloadData: DownloadDataModel(downloadQualities: DownloadQualities())).obs;
  Rx<SeasonData> selectSeason = SeasonData().obs;

  Rx<PosterDataModel> selectedEpisode = PosterDataModel(details: ContentData()).obs;

  RxMap<int, RxList<PosterDataModel>> seasonIdWiseEpisodeList = RxMap();

  RxInt currentEpisodeIndex = (-1).obs;
  RxInt page = 1.obs;
  RxInt currentSeason = 1.obs;

  //-------- More Episodes Screen Variables START --------
  FocusNode seasonSectionFocus = FocusNode();
  FocusNode episodeSectionFocus = FocusNode();

  final ScrollController scrollControl = ScrollController();

  //-------- More Episodes Screen Variables END --------

  final GlobalKey<TrailerPlayerWidgetState> trailerPlayerKey = GlobalKey();

  //-------- Preview Screen Focus & Option State --------
  final FocusNode watchNowFocus = FocusNode();
  final FocusNode optionsRowFocus = FocusNode();
  final FocusNode optionSeasonsFocus = FocusNode();
  final FocusNode optionClipsFocus = FocusNode();
  final FocusNode optionMoreLikeFocus = FocusNode();

  // options: seasons_episodes, clips
  RxString selectedOption = 'seasons_episodes'.obs;
  RxBool pinOptionsToTop = false.obs;

  //-------- Trailer Poster Overlay State --------
  RxBool showPosterOverlay = true.obs;
  RxBool isWatchNowFocused = false.obs;
  RxBool isOptionSeasonsFocused = false.obs;
  RxBool isOptionClipsFocused = false.obs;
  RxBool isOptionMoreLikeFocused = false.obs;

  // Focus for Trailers & Clips cards
  final RxList<FocusNode> clipsFocusNodes = <FocusNode>[].obs;

  final RxList<FocusNode> seasonItemFocusNodes = <FocusNode>[].obs;

  void prepareClipsFocus(int count) {
    if (count < 0) count = 0;
    while (clipsFocusNodes.length < count) {
      clipsFocusNodes.add(FocusNode());
    }
    while (clipsFocusNodes.length > count) {
      clipsFocusNodes.removeLast();
    }
  }

  void focusFirstClipCard() {
    if (clipsFocusNodes.isNotEmpty) {
      try {
        clipsFocusNodes.first.requestFocus();
      } catch (_) {}
    }
  }

  // Watch Now handlers
  void handleWatchNowFocusChange(bool hasFocus) {
    isWatchNowFocused(hasFocus);
    if (hasFocus) {
      FocusSoundService.play();
    }
  }

  KeyEventResult handleWatchNowKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        focusOptionsRow();
        return KeyEventResult.handled;
      }
    }
    if (event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (seasonIdWiseEpisodeList.isEmpty) return KeyEventResult.handled;
      final episodes = seasonIdWiseEpisodeList[selectSeason.value.seasonId];
      if (episodes == null || episodes.isEmpty) return KeyEventResult.handled;
      final ep = episodes[0];
      onSubscriptionLoginCheck(
        title: tvShowDetail.value.details.name,
        planLevel: tvShowDetail.value.details.requiredPlanLevel,
        videoAccess: tvShowDetail.value.details.access,
        callBack: () {
          doIfLogin(onLoggedIn: () {
            if ((ep.details.access == MovieAccess.payPerView) && !ep.details.hasContentAccess.getBoolInt()) {
              showSubscriptionDialog(
                  title: locale.value.rentRequired, msg: locale.value.rentToWatch, color: rentedColor);
            } else if (((ep.details.access == MovieAccess.paidAccess) &&
                isMoviePaid(requiredPlanLevel: ep.details.requiredPlanLevel)) || !ep.details.isDeviceSupported.getBoolInt()) {
              showSubscriptionDialog(
                  title: locale.value.subscriptionRequired, msg: locale.value.pleaseSubscribeOrUpgrade);
            } else {
              currentEpisodeIndex(0);

              /// Navigate to Content Details to fetch episode content and play
              Get.to(() => ContentDetailsScreen(), arguments: ep);
            }
          });
        },
      );
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void handleWatchNowTap() {
    // Same behavior as onSkipTrailerEpisode: play first episode when available
    final episodes = seasonIdWiseEpisodeList[selectSeason.value.seasonId];
    if (episodes != null && episodes.isNotEmpty) {
      try {
        currentEpisodeIndex(0);
        skipTrailer(episode: episodes.first);
      } catch (_) {}
    }
  }

  // Centralized handlers for Options row (used by both overlay and pinned rows)
  void handleSeasonsFocusChange(bool has) {
    isOptionSeasonsFocused(has);
    if (has) {
      FocusSoundService.play();
      try {
        selectedOption('seasons_episodes');
        pinOptionsToTop(true);
      } catch (_) {}
    }
  }

  KeyEventResult handleSeasonsKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        pinOptionsToTop(false);
        watchNowFocus.requestFocus();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        focusSeasonsList();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        selectedOption('clips');
        optionClipsFocus.requestFocus();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void handleSeasonsTap() {
    selectedOption('seasons_episodes');
  }

  void handleClipsFocusChange(bool has) {
    isOptionClipsFocused(has);
    if (has) {
      FocusSoundService.play();
      try {
        selectedOption('clips');
      } catch (_) {}
    }
  }

  KeyEventResult handleClipsKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        selectedOption('seasons_episodes');
        optionSeasonsFocus.requestFocus();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        // Stay within options row behavior unchanged here
        pinOptionsToTop(false);
        watchNowFocus.requestFocus();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        selectedOption('more_like');
        optionMoreLikeFocus.requestFocus();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        // Move into the clips grid -> first card
        prepareClipsFocus(tvShowDetail.value.trailerData.length);
        focusFirstClipCard();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void handleClipsTap() {
    selectedOption('clips');
  }

  void handleMoreLikeFocusChange(bool has) {
    isOptionMoreLikeFocused(has);
    if (has) {
      FocusSoundService.play();
      try {
        selectedOption('more_like');
      } catch (_) {}
    }
  }

  KeyEventResult handleMoreLikeKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        selectedOption('clips');
        optionClipsFocus.requestFocus();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        pinOptionsToTop(false);
        watchNowFocus.requestFocus();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        final list = tvShowDetail.value.suggestedContent;
        if (list.isNotEmpty) {
          try {
            list.first.itemFocusNode.requestFocus();
            return KeyEventResult.handled;
          } catch (_) {}
        }
      }
    }
    return KeyEventResult.ignored;
  }

  void handleMoreLikeTap() {
    selectedOption('more_like');
  }

  void focusOptionsRow() {
    optionsRowFocus.requestFocus();
    optionSeasonsFocus.requestFocus();
  }

  void focusSeasonsList() {
    final int total = tvShowDetail.value.details.seasonList.length;
    if (total <= 0) {
      return;
    }
    final int targetIndex = (currentSeason.value - 1).clamp(0, total - 1);
    if (seasonItemFocusNodes.length > targetIndex) {
      try {
        seasonItemFocusNodes[targetIndex].requestFocus();
      } catch (_) {}
    } else if (seasonItemFocusNodes.isNotEmpty) {
      try {
        seasonItemFocusNodes.first.requestFocus();
      } catch (_) {}
    }
  }

  void focusFirstEpisodeIfAvailable() {
    final list = seasonIdWiseEpisodeList[selectSeason.value.seasonId];
    if (list != null && list.isNotEmpty) {
      try {
        list.first.itemFocusNode.requestFocus();
      } catch (_) {}
    }
  }

  @override
  Future<void> onInit() async {
    log('TvShowPreviewController: onInit called');
    // Reset transient UI state to avoid pinned options showing after hot reload
    try {
      pinOptionsToTop(false);
      selectedOption('seasons_episodes');
      isOptionSeasonsFocused(false);
      isOptionMoreLikeFocused(false);
      isOptionClipsFocused(false);
    } catch (_) {}
    if (Get.arguments is PosterDataModel) {
      final PosterDataModel arg = Get.arguments as PosterDataModel;
      log('TvShowPreviewController: Received PosterDataModel with ID: ${arg.details.id}, Type: ${arg.details.type}');
      // Initialize from argument
      showData(
          ContentModel(details: arg.details, downloadData: DownloadDataModel(downloadQualities: DownloadQualities())));
      trailerData(
          ContentModel(details: arg.details, downloadData: DownloadDataModel(downloadQualities: DownloadQualities())));
      // If argument type isn't tvshow/episode, redirect to ContentDetails directly
      if (arg.details.type != VideoType.tvshow && arg.details.type != VideoType.episode) {
        log('TvShowPreviewController: Non-TV content received. Redirecting to ContentDetailsScreen');
        Get.off(() => ContentDetailsScreen(), arguments: arg);
        return;
      }

      // Derive a reliable TV Show ID: prefer details.id, else fallback to root id.
      final int derivedTvShowId = (arg.details.id > 0) ? arg.details.id : (arg.id > 0 ? arg.id : -1);
      isTrailer(true);
      log('TvShowPreviewController: Calling getTvShowDetail with derived ID: $derivedTvShowId');

      if (derivedTvShowId > 0) {
        await getTvShowDetail(
          showLoader: true,
          tvShowId: derivedTvShowId,
        );
      } else {
        log('TvShowPreviewController: Unable to derive a valid TV Show ID from arguments');
      }
    } else if (Get.arguments is ContentData){
      final ContentData arg = Get.arguments as ContentData;
      log('TvShowPreviewController: Received PosterDataModel with ID: ${arg.id}, Type: ${arg.type}');
      // Initialize from argument
      showData(
          ContentModel(details: arg, downloadData: DownloadDataModel(downloadQualities: DownloadQualities())));
      trailerData(
          ContentModel(details: arg, downloadData: DownloadDataModel(downloadQualities: DownloadQualities())));
      // If argument type isn't tvshow/episode, redirect to ContentDetails directly
      if (arg.type != VideoType.tvshow && arg.type != VideoType.episode) {
        log('TvShowPreviewController: Non-TV content received. Redirecting to ContentDetailsScreen');
        Get.off(() => ContentDetailsScreen(), arguments: arg);
        return;
      }

      // Derive a reliable TV Show ID: prefer details.id, else fallback to root id.
      final int derivedTvShowId = arg.id > 0 ? arg.id : -1;
      isTrailer(true);
      log('TvShowPreviewController: Calling getTvShowDetail with derived ID: $derivedTvShowId');

      if (derivedTvShowId > 0) {
        await getTvShowDetail(
          showLoader: true,
          tvShowId: derivedTvShowId,
        );
      } else {
        log('TvShowPreviewController: Unable to derive a valid TV Show ID from arguments');
      }
    } else {
      log('TvShowPreviewController: No PosterDataModel arguments received');
    }
    super.onInit();
    // Ensure initial focus on Watch Now after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        watchNowFocus.requestFocus();
      } catch (_) {}
    });
  }

  @override
  void onReady() {
    // Extra safeguard post-build for hot-reload: ensure options are not pinned by default
    try {
      pinOptionsToTop(false);
    } catch (_) {}
    super.onReady();
  }

  ///Get Show Details via content module
  Future<void> getTvShowDetail({bool showLoader = true, int tvShowId = -1}) async {
    log('TvShowPreviewController: getTvShowDetail called with tvShowId: $tvShowId');
    isLoading(showLoader);

    final int contentId = tvShowId != -1 ? tvShowId : tvShowDetail.value.id;
    log('TvShowPreviewController: Making API call with contentId: $contentId, type: ${VideoType.tvshow}');

    await getTvShowDetailsFuture(
      CoreServiceApis.getContentDetails(
        contentId: contentId,
        type: VideoType.tvshow,
      ),
    ).then((value) async {
      log('TvShowPreviewController: API response received successfully');
      tvShowDetail(value);
      // Update trailer data so UI can rebuild and play trailer
      trailerData(value);
      _prepareSeasonFocus(value.details.seasonList.length);
      // Show poster first, then play trailer after 3 seconds
      Future.delayed(const Duration(milliseconds: 500), () {
        showPosterOverlay(false);
        trailerPlay();
      });
      isSupportedDevice(value.details.isDeviceSupported.getBoolInt());
      setValue(SharedPreferenceConst.IS_SUPPORTED_DEVICE, value.details.isDeviceSupported.getBoolInt());
      if (value.details.isSeasonAvailable) {
        selectSeason(value.details.seasonList.first);
        await getEpisodeList(forceFetchData: true);
      }
      displaySkipButton(true);
    }).catchError((error) {
      log('TvShowPreviewController: API call failed with error: $error');
    }).whenComplete(() => isLoading(false));
  }

  // Episode detail fetching is handled via content list/details; legacy episodeDetails removed

  Future<void> onNextPage() async {
    if (!isLastPage.value) {
      page.value++;
      await getEpisodeList(forceFetchData: true);
    }
  }

  Future<void> onSwipeRefresh() async {
    page(1);
    await getEpisodeList();
  }

  Future<void> getEpisodeList({bool showLoader = true, bool forceFetchData = false}) async {
    if (!forceFetchData &&
        seasonIdWiseEpisodeList[selectSeason.value.seasonId] != null &&
        seasonIdWiseEpisodeList[selectSeason.value.seasonId]!.isNotEmpty) {
      return;
    }

    isLoadingEpisode(showLoader);
    final int tvShowId = _deriveTvShowId();
    final int seasonId = selectSeason.value.seasonId;
    log('TvShowPreviewController: Fetching episodes with season_id: $seasonId, tv_show_id: $tvShowId');
    final RxList<PosterDataModel> targetList =
        seasonIdWiseEpisodeList.putIfAbsent(selectSeason.value.seasonId, () => RxList<PosterDataModel>());

    await getEpisodeListFuture(
      CoreServiceApis.getEpisodesList(
        page: page.value,
        perPage: 30,
        showId: tvShowId,
        seasonId: seasonId,
        episodeList: targetList,
        lastPageCallBack: (p0) {
          isLastPage(p0);
        },
      ),
    )
        .then((value) {
          // value is RxList for our map, already updated
        })
        .catchError((e) {})
        .whenComplete(() => isLoadingEpisode(false));
  }

  int _deriveTvShowId() {
    // Prefer details.id when this is a tvshow
    final ContentModel current = tvShowDetail.value;
    if (current.details.type == VideoType.tvshow && current.details.id > 0) {
      return current.details.id;
    }
    // If episode context with tvShowData
    if (current.details.tvShowData != null && current.details.tvShowData!.id > 0) {
      return current.details.tvShowData!.id;
    }
    // Fallback to top-level model id
    if (current.id > 0) {
      return current.id;
    }
    // Try initial showData (from navigation arg)
    final ContentModel initial = showData.value;
    if (initial.details.type == VideoType.tvshow && initial.details.id > 0) {
      return initial.details.id;
    }
    if (initial.details.tvShowData != null && initial.details.tvShowData!.id > 0) {
      return initial.details.tvShowData!.id;
    }
    if (initial.id > 0) {
      return initial.id;
    }
    // Try raw argument if available
    if (Get.arguments is PosterDataModel) {
      final PosterDataModel arg = Get.arguments as PosterDataModel;
      if (arg.entertainmentId > 0) return arg.entertainmentId;
      if (arg.details.id > 0) return arg.details.id;
      if (arg.id > 0) return arg.id;
    } 

    if(Get.arguments is ContentData) {
      final ContentData arg = Get.arguments as ContentData;
      if (arg.id > 0) return arg.id;
    }
    return -1;
  }

  void playNextEpisode(PosterDataModel episode) {
    if (episode.id != selectedEpisode.value.id) {
      onSubscriptionLoginCheck(
        planLevel: episode.details.requiredPlanLevel,
        videoAccess: episode.details.access,
        callBack: () async {
          if ((episode.details.access == MovieAccess.payPerView) && !episode.details.hasContentAccess.getBoolInt()) {
            showSubscriptionDialog(title: locale.value.rentRequired, msg: locale.value.rentToWatch, color: rentedColor);
          } else if ((episode.details.access == MovieAccess.paidAccess) &&
              isMoviePaid(requiredPlanLevel: episode.details.requiredPlanLevel)) {
            showSubscriptionDialog(
                title: locale.value.subscriptionRequired, msg: locale.value.pleaseSubscribeOrUpgrade);
          } else {
            selectedEpisode(episode);
            // Map content to video model for player consumption if needed by downstream
            // Keeping existing player integration minimal as URLs are derived downstream
          }
        },
        planId: -1,
      );
    }
  }

  void _prepareSeasonFocus(int count) {
    if (count < 0) count = 0;
    while (seasonItemFocusNodes.length < count) {
      seasonItemFocusNodes.add(FocusNode());
    }
    while (seasonItemFocusNodes.length > count) {
      seasonItemFocusNodes.removeLast();
    }
  }

  void trailerPause() {
    if (trailerPlayerKey.currentState != null && trailerPlayerKey.currentState!.mounted) {
      trailerPlayerKey.currentState?.pause();
    }
  }

  void trailerPlay() {
    if (trailerPlayerKey.currentState != null && trailerPlayerKey.currentState!.mounted) {
      trailerPlayerKey.currentState?.play();
    }
  }

  void onTrailerEnded() {
    // When trailer ends, revert to poster
    showPosterOverlay(true);
    trailerPause();
  }

  void skipTrailer({required PosterDataModel episode}) {
    onSubscriptionLoginCheck(
      planLevel: episode.details.requiredPlanLevel,
      videoAccess: episode.details.access,
      callBack: () async {
        if ((episode.details.access == MovieAccess.payPerView) && !episode.details.hasContentAccess.getBoolInt()) {
          showSubscriptionDialog(title: locale.value.rentRequired, msg: locale.value.rentToWatch, color: rentedColor);
        } else if ((episode.details.access == MovieAccess.paidAccess) &&
            isMoviePaid(requiredPlanLevel: episode.details.requiredPlanLevel)) {
          showSubscriptionDialog(title: locale.value.subscriptionRequired, msg: locale.value.pleaseSubscribeOrUpgrade);
        } else {
          selectedEpisode(episode);
          selectedEpisode.refresh();
          Get.to(() => EpisodePlayerScreen())?.then((res) {
            trailerPlay();
          });
        }
      },
      planId: -1,
    );
  }
}
