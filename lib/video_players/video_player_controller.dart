import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';
import 'package:pod_player/pod_player.dart';
import 'package:streamit_laravel/screens/content/content_details_controller.dart';
import 'package:streamit_laravel/screens/home/home_controller.dart';
import 'package:streamit_laravel/screens/tv_show/tv_show_detail_controller.dart';
import 'package:streamit_laravel/utils/common_base.dart';
import 'package:streamit_laravel/video_players/ad_video_player.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';
import 'package:subtitle/subtitle.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:xml/xml.dart' as xml;
import 'package:xml/xml.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:streamit_laravel/utils/extension/string_extension.dart';

import '../configs.dart';
import '../main.dart';
import '../network/core_api.dart';
import '../screens/dashboard/dashboard_controller.dart';
import '../screens/live_tv/live_tv_details/model/live_tv_details_response.dart';
import '../screens/profile/profile_controller.dart';
import '../utils/app_common.dart';
import '../utils/constants.dart';
import '../services/subtitle_preload_service.dart';
import 'model/ad_config.dart';
import 'model/overlay_ad.dart';
import 'model/vast_ad_response.dart';
import 'model/vast_media.dart';
// Removed deprecated VideoPlayerModel usage. ContentModel is used instead.

class VideoPlayersController extends GetxController {
  UniqueKey uniqueKey = UniqueKey();
  UniqueKey uniqueProgressBarKey = UniqueKey();
  Rx<ContentModel> videoModel = ContentModel(
    details: ContentData(),
    downloadData: DownloadDataModel(downloadQualities: DownloadQualities()),
  ).obs;

  final LiveShowModel liveShowModel;

  Rx<PodPlayerController> podPlayerController =
      PodPlayerController(playVideoFrom: PlayVideoFrom.youtube("")).obs;
  Rx<YoutubePlayerController> youtubePlayerController =
      YoutubePlayerController(initialVideoId: '').obs;
  Rx<WebViewController> webViewController = WebViewController().obs;

  RxBool isAutoPlay = true.obs;
  RxBool isTrailer = true.obs;
  RxBool isStoreContinueWatch = false.obs;
  RxBool isBuffering = false.obs;
  RxBool canChangeVideo = true.obs;
  RxBool playNextVideo = false.obs;
  RxBool isVideoCompleted = false.obs;
  RxBool isVideoPlaying = false.obs;
  RxBool isSkipNextFocused = false.obs;
  // Skip Intro Properties
  RxBool showSkipIntroOverlay = false.obs;

  RxBool isSkipIntroFocused = false.obs;
  RxBool isQualityFocused = false.obs;
  RxBool isSubtitleFocused = false.obs;
  RxBool isProgressBarVisible = false.obs;
  RxBool isLoading = false.obs;
  RxBool showSubtitleOptions = false.obs;
  RxBool showQualityOptions = false.obs;
  RxBool isInitializingPlayer = false.obs;
  RxString currentQuality = QualityConstants.defaultQuality.toLowerCase().obs;
  RxString errorMessage = ''.obs;
  RxString videoUrl = "".obs;
  RxString videoUrlType = "".obs;
  RxString currentSubtitle = ''.obs;

  Rx<Duration> currentVideoPosition = Duration.zero.obs;
  Rx<Duration> currentVideoTotalDuration = Duration.zero.obs;

  // Video Setting Dialog State
  RxList<int> availableQualities = <int>[].obs;
  RxList<VideoData> videoQualities = <VideoData>[].obs;
  RxList<Subtitle> availableSubtitleList = <Subtitle>[].obs;
  RxList<SubtitleModel> subtitleList = <SubtitleModel>[].obs;
  Rx<SubtitleModel> selectedSubtitleModel = SubtitleModel().obs;

  // Use shared subtitle preload service for cache management
  final SubtitlePreloadService _subtitlePreloadService =
      SubtitlePreloadService();

  // Focus nodes
  FocusNode qualityTabFocusNode = FocusNode();
  FocusNode subtitleTabFocusNode = FocusNode();
  FocusNode videoFocusNode = FocusNode();
  FocusNode skipNextVideoFocusNode = FocusNode();
  FocusNode skipAdFocusNode = FocusNode();
  FocusNode skipIntroFocusNode = FocusNode();

  /// Ensures that the main video focus node regains focus once
  /// overlay interactions (like subtitles/quality) are completed.
  /// When [immediate] is true the focus request happens synchronously,
  /// otherwise it is deferred to the next frame to allow current focus
  /// updates to settle.
  void requestVideoFocus({bool immediate = false}) {
    void request() {
      if (!videoFocusNode.canRequestFocus) return;
      final context = Get.context;
      if (context != null) {
        FocusScope.of(context).requestFocus(videoFocusNode);
      } else {
        videoFocusNode.requestFocus();
      }
    }

    if (immediate) {
      request();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => request());
    }
  }

  Timer? _hideProgressBarTimer;
  VoidCallback? onVideoChange;
  VoidCallback? onWatchNextVideo;

  // Add focus management for quality list
  RxInt focusedQualityIndex = (-1).obs;
  RxInt focusedSubtitleIndex = (-1).obs;

  // Add debounce variables to prevent rapid key events
  DateTime? _lastQualityNavigationTime;
  DateTime? _lastSubtitleNavigationTime;
  static const Duration _navigationDebounceTime = Duration(milliseconds: 100);

  // Ads Properties
  RxBool isAdPlaying = false.obs;
  RxBool isSkipAdFocused = false.obs;
  RxString adVideoUrl = "".obs;
  RxInt adSkipTimer = 5.obs;
  Timer? adSkipTimerController;
  Set<int> midRollAdSeconds = {};
  int adFrequency = 1;
  final Set<int> shownMidRollAds = {};
  RxBool isPostRollAdShown = false.obs;
  final RxBool isCurrentAdSkippable = false.obs;
  RxInt currentAdIndex = 0.obs;

  List<AdConfig> preRollAds = [];
  List<AdConfig> midRollAds = [];
  List<AdConfig> postRollAds = [];

  Completer<void>? _currentAdCompleter;

  RxInt lastPlaybackPosition = 0.obs;

  RxList<OverlayAd> overlayAds = <OverlayAd>[].obs;
  Rx<OverlayAd?> currentOverlayAd = Rx<OverlayAd?>(null);
  Timer? overlayAdTimer;
  final Set<int> shownOverlayAds = {};

  RxBool hasShownCustomAd = true.obs;

  RxBool isResumingFromAd = false.obs;

  /// x265 specific flags
  bool hasAttemptedForcePlay = false;
  bool hasAttemptedReinitialize = false;

  final GlobalKey<ADVideoPlayerWidgetState> adViewPlayerKey = GlobalKey();
  VoidCallback adPlayerListener = () {};

  Rx<Duration?> lastYoutubePositionBeforeAd = Rx<Duration?>(null);
  RxBool shouldResumeAfterAd = false.obs;

  //Constructor
  VideoPlayersController(
      {required this.videoModel,
      required this.liveShowModel,
      required this.isTrailer,
      this.onVideoChange,
      this.onWatchNextVideo});

  RxBool hasNextVideo = false.obs;
  bool _isCurrentlyInitializing = false;

  @override
  void onInit() {
    super.onInit();
    // Initialize adPlayer and adVideoController

    _setupDynamicAds().then(
      (value) {
        isBuffering(false);
        // Ensure isResumingFromAd is false before initializing player (to allow pre-roll ads)
        isResumingFromAd(false);
        initializePlayer().whenComplete(
          () => hasShownCustomAd(videoModel.value.isPurchased),
        );
      },
    ).onError(
      (error, stackTrace) {
        isBuffering(false);
        // Even if ad setup fails, initialize player
        isResumingFromAd(false);
        initializePlayer();
      },
    );
    WakelockPlus.enable();
    onPlayOriginalVideo();
    onUpdateSubtitle();
    onUpdateQualities();
    onIntroDurationUpdate();
    //endregion

    setInitialFocusesForSubtitleAndQuality();
    onPlayPauseEmitRecived();
    onChangePodVideo();

    // Set up skip intro listener early
    showSkipIntroButton();
  }

  /// Get all ad break points including midroll, postroll, and overlay ads
  ///
  /// This method consolidates all ad break points from different ad types:
  /// - Midroll ads: Scheduled at specific time intervals during video playback
  /// - Overlay ads: Displayed as overlays at specific time points
  /// - Postroll ads: Displayed at 90% of video duration
  ///
  /// Returns a sorted list of unique Duration objects representing all ad break points
  List<Duration> getAllAdBreaks() {
    final List<Duration> allBreaks = [];

    // Add midroll ad breaks
    if (midRollAdSeconds.isNotEmpty) {
      allBreaks.addAll(
          midRollAdSeconds.map((seconds) => Duration(seconds: seconds)));
    }

    // Add overlay ad breaks
    if (overlayAds.isNotEmpty) {
      allBreaks.addAll(overlayAds.map((ad) => Duration(seconds: ad.startTime)));
    }

    if (postRollAds.isNotEmpty && !isPostRollAdShown.value) {
      final videoDuration =
          podPlayerController.value.videoPlayerValue?.duration ?? Duration.zero;
      if (videoDuration.inSeconds > 0) {
        final isEpisode = _isEpisodeContent();
        final postRollPercentage = isEpisode ? 0.7 : 0.9;
        final postRollPosition =
            (videoDuration.inSeconds * postRollPercentage).round();
        log('+-+-+-+-+-+-+-+-+-Post-roll ad timing: ${isEpisode ? "EPISODE" : "OTHER"} content - ${(postRollPercentage * 100).toInt()}% (${formatSecondsToHMS(postRollPosition)})');
        allBreaks.add(Duration(seconds: postRollPosition));
      }
    }

    // Remove duplicates and sort by time
    final uniqueBreaks = allBreaks.toSet().toList();
    uniqueBreaks.sort((a, b) => a.inSeconds.compareTo(b.inSeconds));

    return (videoModel.value.isPurchased || isTrailer.value == true)
        ? []
        : uniqueBreaks;
  }

  /// Check if a specific position is an ad break point
  ///
  /// [position] - The current video position in seconds
  /// Returns true if the position matches any ad break point
  bool isAdBreakPoint(int position) {
    final adBreaks = getAllAdBreaks();
    return adBreaks.any((breakPoint) => breakPoint.inSeconds == position);
  }

  /// Get the next ad break point after a given position
  ///
  /// [position] - The current video position in seconds
  /// Returns the next ad break point or null if no more breaks
  Duration? getNextAdBreak(int position) {
    final adBreaks = getAllAdBreaks();
    final nextBreaks = adBreaks
        .where((breakPoint) => breakPoint.inSeconds > position)
        .toList();
    return nextBreaks.isNotEmpty ? nextBreaks.first : null;
  }

  /// Check if the current content is an episode
  bool _isEpisodeContent() {
    final contentType = videoModel.value.type.toLowerCase();
    final entertainmentType = videoModel.value.entertainmentType.toLowerCase();

    if (contentType == 'episode') {
      return true;
    }

    if (entertainmentType == 'episode') {
      return true;
    }

    if (videoModel.value.episodeId > 0) {
      return true;
    }

    return false;
  }

  Future<void> _setupDynamicAds() async {
    // Skip ad setup for trailers
    // if (isTrailer.value) {
    //   return;
    // }
    // if (videoModel.value.isPurchased) return;

    // First, check for VAST ads in the content model's ads_data
    List<VastAd> contentModelAds = [];
    if (videoModel.value.adsData != null) {
      final vastAds = videoModel.value.adsData!.vastAds;

      // Convert content model VAST URLs to VastAd objects
      for (final url in vastAds.preRoleAdUrl) {
        if (url.isNotEmpty) {
          contentModelAds.add(VastAd(
            type: 'pre-roll',
            url: url,
            targetType: videoModel.value.type,
            targetSelection: videoModel.value.id.toString(),
          ));
        }
      }
      for (final url in vastAds.midRoleAdUrl) {
        if (url.isNotEmpty) {
          contentModelAds.add(VastAd(
            type: 'mid-roll',
            url: url,
            targetType: videoModel.value.type,
            targetSelection: videoModel.value.id.toString(),
          ));
        }
      }
      for (final url in vastAds.postRoleAdUrl) {
        if (url.isNotEmpty) {
          contentModelAds.add(VastAd(
            type: 'post-roll',
            url: url,
            targetType: videoModel.value.type,
            targetSelection: videoModel.value.id.toString(),
          ));
        }
      }
      for (final url in vastAds.overlayAdUrl) {
        if (url.isNotEmpty) {
          contentModelAds.add(VastAd(
            type: 'overlay',
            url: url,
            targetType: videoModel.value.type,
            targetSelection: videoModel.value.id.toString(),
          ));
        }
      }
    }

    // Also get VAST ads from dashboard controller (for global ads)
    final dashboardController = Get.find<DashboardController>();
    if (dashboardController.vastAds.isEmpty) {
      await dashboardController.getActiveVastAds();
    }

    final allVastAds = dashboardController.vastAds;

    final contentIdForAds = (videoModel.value.type.toLowerCase() == 'episode')
        ? videoModel.value.id // Use episode ID for episodes
        : (videoModel.value.entertainmentId > 0
            ? videoModel.value.entertainmentId
            : videoModel.value.id);

    final applicableDashboardAds = _getApplicableVastAdsForContent(
      contentType: videoModel.value.type,
      contentId: contentIdForAds,
      allAds: allVastAds,
    );

    // Combine: content model ads (always applicable) + filtered dashboard ads
    final applicableAds = [...contentModelAds, ...applicableDashboardAds];
    log('+-+-+-+-+-+-+-+-+-Video type: ${videoModel.value.type}, Video ID: ${videoModel.value.id}');
    final grouped = _groupVastAdsByType(applicableAds);
    log('+-+-+-+-+-+-+-+-+-Grouped ads by type: ${grouped.keys.toList()}');
    log('+-+-+-+-+-+-+-+-+-Grouped ads details: ${grouped.map((key, value) => MapEntry(key, value.length)).toString()}');

    preRollAds = await _mapVastAdsToAdConfigs(grouped['pre-roll'] ?? []);
    log('+-+-+-+-+-+-+-+-+-check is pre-roll: ${preRollAds.length} -- ${preRollAds.map((e) => e.url)}');
    midRollAds = await _mapVastAdsToAdConfigs(grouped['mid-roll'] ?? []);
    log('+-+-+-+-+-+-+-+-+-check is mid-roll: ${midRollAds.length} -- ${midRollAds.map((e) => e.url)}');
    postRollAds = await _mapVastAdsToAdConfigs(grouped['post-roll'] ?? []);
    log('+-+-+-+-+-+-+-+-+-check is post-roll: ${postRollAds.length} -- ${postRollAds.map((e) => e.url)}');
    overlayAds.value = await _mapVastAdsToOverlayAds(grouped['overlay'] ?? []);
    log('+-+-+-+-+-+-+-+-+-check is overlay: ${overlayAds.length} -- ${overlayAds.map((e) => e.imageUrl)}');
    if ((grouped['mid-roll'] ?? []).isNotEmpty) {
      final ad = grouped['mid-roll']!.first;
      if (ad.frequency != null && ad.frequency! > 0) {
        adFrequency = ad.frequency!;
      } else {
        adFrequency = 1;
      }
      log('+-+-+-+-+-+-+-+-+-Mid-roll frequency set to: $adFrequency from ad: ${ad.toJson()}');
    } else {
      log('+-+-+-+-+-+-+-+-+-No mid-roll ads found, frequency remains: $adFrequency');
    }
  }

  bool skipIntroHandled = false;
  bool _skipIntroListenerSet = false;

  void onIntroDurationUpdate() {
    LiveStream().on(REFRESH_INTRO_DURATION, (val) async {
      if (val is Map<String, dynamic>) {
        log('+-+-+-+-+-+-+-+-+-Intro duration updated: intro_starts_at=${val['intro_starts_at']}, intro_ends_at=${val['intro_ends_at']}');
        videoModel.value.details.introStartsAt = val['intro_starts_at'];
        videoModel.value.details.introEndsAt = val['intro_ends_at'];
        // Reset skip intro state when intro duration is updated
        skipIntroHandled = false;
        showSkipIntroOverlay.value = false;
        log('+-+-+-+-+-+-+-+-+-Skip intro state reset after intro duration update');
      }
    });
  }

  void showSkipIntroButton() {
    // Don't set up listener for these content types
    if (videoModel.value.type == VideoType.tvshow ||
        videoModel.value.type == VideoType.liveTv ||
        videoModel.value.type == VideoType.video) {
      log('+-+-+-+-+-+-+-+-+-Skip intro: Content type ${videoModel.value.type} does not support skip intro');
      return;
    }

    // Set up listener only once, but it will check isTrailer dynamically
    if (!_skipIntroListenerSet) {
      _skipIntroListenerSet = true;
      log('+-+-+-+-+-+-+-+-+-Setting up skip intro button listener');
      log('+-+-+-+-+-+-+-+-+-Initial intro times: introStartsAt="${videoModel.value.introStartsAt}", introEndsAt="${videoModel.value.introEndsAt}"');
      ever<Duration>(currentVideoPosition, (position) {
        // Only show skip intro button when NOT in trailer mode
        if (isTrailer.value) {
          if (showSkipIntroOverlay.value) {
            showSkipIntroOverlay.value = false;
            isSkipIntroFocused.value = false;
            skipIntroFocusNode.unfocus();
          }
          return;
        }

        // Recalculate intro times dynamically in case they were updated
        int introStart = parseDurationToSeconds(videoModel.value.introStartsAt);
        int introEnd = parseDurationToSeconds(videoModel.value.introEndsAt);

        // Skip if intro times are invalid
        // Allow introStart == 0 (intro can start at 00:00)
        if (introStart < 0 || introEnd <= 0 || introEnd <= introStart) {
          // Log more frequently to debug
          if (position.inSeconds % 10 == 0 && position.inSeconds < 30) {
            log('+-+-+-+-+-+-+-+-+-Skip intro: Invalid intro times (introStart=$introStart, introEnd=$introEnd, raw: "${videoModel.value.introStartsAt}" -> "${videoModel.value.introEndsAt}")');
          }
          return;
        }

        int currentPosition = position.inSeconds;

        // Log every 5 seconds to track progress
        if (currentPosition % 5 == 0 && currentPosition <= introEnd + 10) {
          log('+-+-+-+-+-+-+-+-+-Skip intro check: position=$currentPosition, introStart=$introStart, introEnd=$introEnd, skipIntroHandled=$skipIntroHandled, showSkipIntroOverlay=${showSkipIntroOverlay.value}, isTrailer=${isTrailer.value}');
        }

        // Show when inside intro range
        if (!skipIntroHandled &&
            currentPosition >= introStart &&
            currentPosition <= introEnd) {
          log('+-+-+-+-+-+-+-+-+-*** SHOWING SKIP INTRO BUTTON *** at position $currentPosition (intro range: $introStart-$introEnd)');
          log('+-+-+-+-+-+-+-+-+-Current state: isLoading=${isLoading.value}, isVideoPlaying=${isVideoPlaying.value}');
          skipIntroHandled = true;
          // Ensure loading is false so button can be visible
          if (isLoading.value) {
            log('+-+-+-+-+-+-+-+-+-Warning: isLoading is true, setting to false to show skip intro button');
            isLoading(false);
          }
          showSkipIntroOverlay.value = true;
          // Auto-focus the skip intro button
          focusSkipIntroButton();
        }

        // Hide once intro is passed
        if (skipIntroHandled && currentPosition > introEnd) {
          log('+-+-+-+-+-+-+-+-+-Hiding skip intro button (passed intro end at $introEnd)');
          showSkipIntroOverlay.value = false;
          isSkipIntroFocused.value = false;
          skipIntroFocusNode.unfocus();
        }
      });
    } else {
      // Listener already set up, but log that we're checking
      log('+-+-+-+-+-+-+-+-+-Skip intro listener already set up, current position: ${currentVideoPosition.value.inSeconds}s, isTrailer: ${isTrailer.value}');
    }
  }

  Future<void> onSkipIntro() async {
    showSkipIntroOverlay(false);
    isSkipIntroFocused.value = false;
    skipIntroFocusNode.unfocus();

    Duration duration =
        Duration(seconds: parseDurationToSeconds(videoModel.value.introEndsAt));
    if (youtubePlayerController.value.value.isReady) {
      youtubePlayerController.value.seekTo(duration);
    } else if (podPlayerController.value.isInitialised) {
      podPlayerController.value.videoSeekForward(duration);
    } else if (await webViewController.value.currentUrl() != null) {
      webViewController.value
          .runJavaScript('seekTo(${(duration.inSeconds).toString()})');
    }

    // Return focus to main video controls
    Future.delayed(Duration(milliseconds: 200), () {
      requestVideoFocus();
    });
  }

  /// Manually focus the skip intro button
  void focusSkipIntroButton() {
    if (showSkipIntroOverlay.value) {
      skipIntroFocusNode.requestFocus();
      isSkipIntroFocused.value = true;
    }
  }

  Future<List<AdConfig>> _mapVastAdsToAdConfigs(List<VastAd> ads) async {
    List<AdConfig> result = [];
    for (final ad in ads) {
      log('+-+-+-+-+-+-+-+-+-Processing ad: type=${ad.type}, url=${ad.url}');
      if ((ad.url ?? '').isEmpty) {
        log('+-+-+-+-+-+-+-+-+-WARNING: Ad URL is empty, skipping');
        continue;
      }
      if ((ad.url ?? '').toLowerCase().endsWith('.xml')) {
        final vastMedia = await fetchVastMedia(ad.url!);
        if (vastMedia != null && vastMedia.mediaUrls.isNotEmpty) {
          final skipSeconds = vastMedia.skipDuration ??
              (parseDurationToSeconds(ad.skipAfter) == 0
                  ? 5
                  : parseDurationToSeconds(ad.skipAfter));
          final lastIndex = vastMedia.mediaUrls.length - 1;
          for (int i = 0; i < vastMedia.mediaUrls.length; i++) {
            log('+-+-+-+-+-+-+-+-+-Adding VAST ad config: URL=${vastMedia.mediaUrls[i]}, skippable=${i == lastIndex && skipSeconds > 0}');
            result.add(AdConfig(
              url: vastMedia.mediaUrls[i],
              isSkippable: i == lastIndex && skipSeconds > 0,
              skipAfterSeconds: skipSeconds,
              type: 'video',
              clickThroughUrl: (i < vastMedia.clickThroughUrls.length)
                  ? vastMedia.clickThroughUrls[i]
                  : null,
            ));
          }
        }
      } else {
        final adConfig = _adConfigFromVastAd(ad);
        if (adConfig.url.isNotEmpty) {
          result.add(adConfig);
        }
      }
    }
    return result;
  }

  Future<List<OverlayAd>> _mapVastAdsToOverlayAds(List<VastAd> ads) async {
    List<OverlayAd> result = [];
    for (final ad in ads) {
      if ((ad.url ?? '').toLowerCase().endsWith('.xml')) {
        final vastMedia = await fetchVastMedia(ad.url!);
        if (vastMedia != null && vastMedia.overlayAds.isNotEmpty) {
          result.addAll(vastMedia.overlayAds);
          log('+-+-+-+-+-+-+-+-+-VAST XML overlay ads parsed: ${vastMedia.overlayAds.length} from ${ad.url}');
          for (final overlayAd in vastMedia.overlayAds) {
            log('+-+-+-+-+-+-+-+-+-Overlay ad: startTime=${overlayAd.startTime}s, duration=${overlayAd.duration}s, imageUrl=${overlayAd.imageUrl}');
          }
        } else {
          log('+-+-+-+-+-+-+-+-+-No overlay ads found in VAST XML: ${ad.url}');
        }
      } else {
        result.add(_overlayAdFromVastAd(ad));
      }
    }
    return result;
  }

  List<VastAd> _getApplicableVastAdsForContent({
    required String contentType,
    required int contentId,
    required List<VastAd> allAds,
  }) {
    log('+-+-+-+-+-+-+-+-+-check is _getApplicableVastAdsForContent: "$contentType", $contentId, total ads: ${allAds.length}');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    String actualContentType = contentType;
    if (actualContentType.isEmpty) {
      actualContentType = videoModel.value.type.toLowerCase();

      if (actualContentType.isEmpty) {
        if (videoModel.value.entertainmentType.isNotEmpty) {
          actualContentType = videoModel.value.entertainmentType.toLowerCase();
        } else if (videoModel.value.episodeId > 0) {
          actualContentType = 'episode';
        } else if (videoModel.value.category.toLowerCase().contains('movie') ||
            videoModel.value.name.toLowerCase().contains('movie')) {
          actualContentType = 'movie';
        } else if (videoModel.value.seasonId > 0) {
          actualContentType = 'tvshow';
        } else {
          if (videoModel.value.watchedTime.isNotEmpty &&
              videoModel.value.watchedTime != '00:00:00') {
            actualContentType = 'video';
          } else {
            actualContentType = 'movie';
          }
        }
      }
    }

    return allAds.where((ad) {
      String normalizedContentType = actualContentType.toLowerCase();
      if (normalizedContentType == 'episode') {
        normalizedContentType = 'tvshow';
      }
      if ((ad.targetType ?? '').toLowerCase() != normalizedContentType) {
        return false;
      }
      if (ad.targetSelection == null) {
        return false;
      }
      final cleaned = ad.targetSelection!
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll(' ', '');
      final ids = cleaned.split(',').toSet();
      if (!ids.contains(contentId.toString())) {
        return false;
      }
      if (ad.startDate != null) {
        final adStartDate = ad.startDate!;
        final adStartDay =
            DateTime(adStartDate.year, adStartDate.month, adStartDate.day);
        if (adStartDay.isAfter(today)) return false;
      }

      if (ad.endDate != null) {
        final adEndDate = ad.endDate!;
        final adEndDay =
            DateTime(adEndDate.year, adEndDate.month, adEndDate.day);
        if (adEndDay.isBefore(today)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Map<String, List<VastAd>> _groupVastAdsByType(List<VastAd> ads) {
    final map = <String, List<VastAd>>{};
    for (final ad in ads) {
      final type = ad.type?.toLowerCase() ?? '';
      map.putIfAbsent(type, () => []).add(ad);
    }
    return map;
  }

  AdConfig _adConfigFromVastAd(VastAd ad) {
    return AdConfig(
      url: ad.url ?? '',
      isSkippable: ad.enableSkip ?? false,
      skipAfterSeconds: (parseDurationToSeconds(ad.skipAfter) == 0
          ? 5
          : parseDurationToSeconds(ad.skipAfter)),
      type: 'video',
    );
  }

  OverlayAd _overlayAdFromVastAd(VastAd ad) {
    return OverlayAd(
      imageUrl: ad.url ?? '',
      clickThroughUrl: null,
      startTime: int.tryParse(ad.duration ?? '0') ?? 0,
      duration: ad.frequency ?? 10,
    );
  }

  void calculateMidRollTimes(Duration duration) {
    midRollAdSeconds.clear();
    int totalDurationInSeconds = duration.inSeconds;

    if (totalDurationInSeconds <= 0 || adFrequency <= 0) {
      return;
    }

    for (int i = 1; i <= adFrequency; i++) {
      final adTime = (totalDurationInSeconds * i / (adFrequency + 1)).round();
      final minTime = totalDurationInSeconds > 120
          ? 30
          : 10; // 30s for long videos, 10s for short
      final maxTime =
          totalDurationInSeconds - (totalDurationInSeconds > 120 ? 30 : 10);
      if (adTime >= minTime && adTime <= maxTime) {
        midRollAdSeconds.add(adTime);
      }
    }
  }

  Timer? checkTimer;

  void startCheckingValue() async {
    checkTimer?.cancel();

    checkTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (adViewPlayerKey.currentState != null &&
          adViewPlayerKey.currentState!.isEnded) {
        await skipAd();
        // Stop the timer when ad is completed
        timer.cancel();
      }
    });
  }

  Future<void> playAd(AdConfig adConfig) async {
    if (isAdPlaying.value) {
      return;
    }

    // Hide any currently visible overlay ads when starting a video ad
    if (currentOverlayAd.value != null) {
      overlayAdTimer?.cancel();
      currentOverlayAd.value = null;
    }

    final completer = Completer<void>();
    _currentAdCompleter = completer;
    try {
      isAdPlaying(true);
      isCurrentAdSkippable.value = adConfig.isSkippable;
      startCheckingValue();

      if (podPlayerController.value.isInitialised) {
        podPlayerController.value.pause();
      }
      if (youtubePlayerController.value.value.isReady) {
        lastYoutubePositionBeforeAd(
            youtubePlayerController.value.value.position);
        youtubePlayerController.value.pause();
      }
      if (isWebViewActive()) {
        log('+-+-+-+-+-+-+-+-+-Pausing WebView for ad');

        /// WebView pause is handled via JavaScript in skipAd
      }

      // Validate ad URL
      if (adConfig.url.isEmpty) {
        throw Exception('Ad URL is empty');
      }

      adVideoUrl(adConfig.url);

      // Wait for the widget to be built and initialized
      log('+-+-+-+-+-+-+-+-+-Waiting for ad player widget to be ready...');
      int attempts = 0;
      while (adViewPlayerKey.currentState == null && attempts < 20) {
        await Future.delayed(Duration(milliseconds: 100));
        attempts++;
        if (attempts % 5 == 0) {
          log('+-+-+-+-+-+-+-+-+-Still waiting for ad player widget... (attempt $attempts/20)');
        }
      }

      if (adViewPlayerKey.currentState == null) {
        throw Exception('Ad player widget not initialized');
      }

      log('+-+-+-+-+-+-+-+-+-Ad player widget is ready after ${attempts * 100}ms');

      // Verify the widget has the correct URL
      // The widget should rebuild when adVideoUrl changes, but let's give it a moment
      await Future.delayed(Duration(milliseconds: 200));

      adPlayerListener = () async {
        if (adViewPlayerKey.currentState != null &&
            adViewPlayerKey.currentState!.isEnded) {
          await skipAd();
          if (!completer.isCompleted) completer.complete();
        }
      };

      if (adViewPlayerKey.currentState == null) {
        throw Exception('Ad player widget state is null');
      }

      adViewPlayerKey.currentState?.addListeners();

      adViewPlayerKey.currentState?.play();

      // Wait a bit and check if ad is actually playing
      await Future.delayed(Duration(milliseconds: 500));
      if (adViewPlayerKey.currentState != null) {
        log('+-+-+-+-+-+-+-+-+-Ad player state - isPlaying: ${adViewPlayerKey.currentState!.isPlaying}, isEnded: ${adViewPlayerKey.currentState!.isEnded}');
      }

      if (adConfig.isSkippable) {
        adSkipTimer(adConfig.skipAfterSeconds);

        adSkipTimerController = Timer.periodic(Duration(seconds: 1), (timer) {
          if (adSkipTimer.value > 0) {
            if (adViewPlayerKey.currentState != null &&
                adViewPlayerKey.currentState!.isPlaying) {
              adSkipTimer.value--;
            }
          } else {
            skipAdFocusNode.requestFocus();
            timer.cancel();
          }
        });
      }
    } catch (e, stackTrace) {
      log("+-+-+-+-+-+-+-+-+-ERROR playing ad: $e");
      log("+-+-+-+-+-+-+-+-+-Stack trace: $stackTrace");
      await skipAd();
      if (!completer.isCompleted) completer.complete();
    }

    await completer.future;
  }

  Future<void> skipAd() async {
    try {
      adSkipTimerController?.cancel();
      checkTimer?.cancel();

      adViewPlayerKey.currentState?.removeListeners();
      adViewPlayerKey.currentState?.pause();
      isAdPlaying(false);
      isSkipAdFocused(false);
      skipAdFocusNode.unfocus();

      if (_currentAdCompleter != null && !_currentAdCompleter!.isCompleted) {
        _currentAdCompleter!.complete();
      }

      isResumingFromAd(true);

      final isLocalVideo =
          videoUrlType.value.toLowerCase() == PlayerTypes.local.toLowerCase();

      if (podPlayerController.value.isInitialised) {
        // SPECIAL HANDLING FOR LOCAL VIDEOS
        if (isLocalVideo) {
          log('+-+-+-+-+-+-+-+-+-Resuming Local video after ad');

          try {
            // Check if player is still valid
            if (!podPlayerController.value.isInitialised) {
              log('+-+-+-+-+-+-+-+-+-Player not initialized, reinitializing');
              await initializePodPlayer(videoUrl.value);
              isResumingFromAd(false);
              isBuffering(false);
              return;
            }

            // For MID-ROLL ads, just resume playback without reinitializing
            final currentPosition =
                podPlayerController.value.currentVideoPosition;

            if (currentPosition.inSeconds > 10) {
              // This is likely a mid-roll ad - player is already initialized
              log('+-+-+-+-+-+-+-+-+-Mid-roll ad completed, resuming playback at ${currentPosition.inSeconds}s');

              // Simple resume for mid-roll
              isBuffering(false);
              podPlayerController.value.play();

              // Verify playback resumed
              Future.delayed(Duration(milliseconds: 500), () {
                if (podPlayerController.value.isVideoPlaying) {
                  log('+-+-+-+-+-+-+-+-+-Local video resumed successfully after mid-roll');
                  isResumingFromAd(false);
                } else {
                  log('+-+-+-+-+-+-+-+-+-Retrying play after mid-roll');
                  podPlayerController.value.play();
                  Future.delayed(Duration(milliseconds: 500), () {
                    isResumingFromAd(false);
                  });
                }
              });
              return;
            } else {
              // This is a PRE-ROLL ad - need full reinitialization
              log('+-+-+-+-+-+-+-+-+-Pre-roll ad completed, full reinitialization');

              // Complete disposal
              podPlayerController.value.dispose();
              await Future.delayed(const Duration(milliseconds: 400));

              // Force UI rebuild
              uniqueKey = UniqueKey();
              uniqueProgressBarKey = UniqueKey();
              update();

              await Future.delayed(const Duration(milliseconds: 600));

              // Reinitialize
              await initializePodPlayer(videoUrl.value);

              isResumingFromAd(false);
              isBuffering(false);
              return;
            }
          } catch (e) {
            log('+-+-+-+-+-+-+-+-+-Error resuming Local video: $e');
            // Fallback: try to reinitialize
            try {
              await initializePodPlayer(videoUrl.value);
            } catch (e2) {
              log('+-+-+-+-+-+-+-+-+-Failed to reinitialize: $e2');
            }
            isResumingFromAd(false);
            isBuffering(false);
            return;
          }
        }

        // HLS handling
        if (videoUrlType.value.toLowerCase() == PlayerTypes.hls.toLowerCase()) {
          try {
            podPlayerController.value.play();
            await Future.delayed(const Duration(milliseconds: 1000));

            if (podPlayerController.value.isVideoPlaying) {
              isBuffering(false);
              isResumingFromAd(false);
              return;
            } else {
              final currentPosition =
                  podPlayerController.value.currentVideoPosition;
              podPlayerController.value.dispose();
              await Future.delayed(const Duration(milliseconds: 500));

              uniqueKey = UniqueKey();
              update();

              await Future.delayed(const Duration(milliseconds: 500));
              await initializePodPlayer(videoUrl.value);

              if (currentPosition.inSeconds > 5) {
                Future.delayed(const Duration(milliseconds: 1000), () {
                  if (podPlayerController.value.isInitialised) {
                    podPlayerController.value.videoSeekForward(currentPosition);
                  }
                });
              }

              isResumingFromAd(false);
              return;
            }
          } catch (e) {
            log('+-+-+-+-+-+-+-+-+-Error during HLS resume: $e');
            podPlayerController.value.play();
          }
        } else {
          // Standard video handling
          podPlayerController.value.play();
        }

        Future.delayed(const Duration(milliseconds: 500), () {
          if (podPlayerController.value.isVideoPlaying) {
            isBuffering(false);
            isResumingFromAd(false);
          } else {
            Future.delayed(const Duration(seconds: 2), () {
              isBuffering(false);
              isResumingFromAd(false);
            });
          }
        });
      } else if (youtubePlayerController.value.value.isReady) {
        log('+-+-+-+-+-+-+-+-+-Resuming YouTube content');
        if (lastYoutubePositionBeforeAd.value != null) {
          youtubePlayerController.value
              .seekTo(lastYoutubePositionBeforeAd.value ?? Duration.zero);
        }
        youtubePlayerController.value.play();
        lastYoutubePositionBeforeAd.value = null;
        isBuffering(false);
        isResumingFromAd(false);
      } else if (isWebViewActive()) {
        log('+-+-+-+-+-+-+-+-+-Resuming WebView content (${videoUrlType.value})');
        try {
          webViewController.value.runJavaScript(
              'try{ if (window.player && typeof window.player.playVideo === "function"){ try{ if(typeof window.player.mute === "function") window.player.mute(); }catch(e){} window.player.playVideo(); } else { var v = document.querySelector("video"); if (v){ try{ v.muted = true; }catch(e){} v.play(); } } }catch(e){}');
          isBuffering(false);
          isResumingFromAd(false);
        } catch (e) {
          log('Error resuming embedded video after ad: $e');
          isBuffering(false);
          isResumingFromAd(false);
        }
      } else {
        log('+-+-+-+-+-+-+-+-+-Player not initialized after ad');
        if (videoUrlType.value.toLowerCase() ==
                PlayerTypes.local.toLowerCase() ||
            videoUrlType.value.toLowerCase() == PlayerTypes.url.toLowerCase() ||
            videoUrlType.value.toLowerCase() == PlayerTypes.hls.toLowerCase() ||
            videoUrlType.value.toLowerCase() ==
                PlayerTypes.x265.toLowerCase()) {
          await initializePodPlayer(videoUrl.value);
        } else {
          shouldResumeAfterAd(true);
          Future.delayed(const Duration(seconds: 5), () {
            shouldResumeAfterAd(false);
            isResumingFromAd(false);
          });
        }
      }
    } catch (e) {
      log("Error skipping ad: $e");
      isResumingFromAd(false);
      isBuffering(false);
    }
  }

  Future<void> playVastAd(String vastUrl) async {
    preRollAds.clear();
    final vastMedia = await fetchVastMedia(vastUrl);
    if (vastMedia != null) {
      for (int i = 0; i < vastMedia.mediaUrls.length; i++) {
        final isLastVideo = i == vastMedia.mediaUrls.length - 1;
        preRollAds.add(AdConfig(
          url: vastMedia.mediaUrls[i],
          isSkippable: isLastVideo,
          skipAfterSeconds: isLastVideo ? 5 : 0,
          clickThroughUrl: (i < vastMedia.clickThroughUrls.length)
              ? vastMedia.clickThroughUrls[i]
              : null,
        ));
      }
    } else {
      log('No valid media file found in VAST');
    }
  }

  Future<VastMedia?> fetchVastMedia(String vastUrl) async {
    try {
      final response = await http.get(Uri.parse(vastUrl));

      if (response.statusCode != 200) return null;

      String xmlString = response.body
          .replaceAll('<IconClicks>', '<Iconclicks>')
          .replaceAll('</IconClicks>', '</Iconclicks>');

      final document = xml.XmlDocument.parse(xmlString);

      final mediaUrls = document
          .findAllElements('MediaFile')
          .where((e) => e.getAttribute('type') == 'video/mp4')
          .map((e) => e.innerText.trim())
          .toList();

      final clickThroughUrls = document
          .findAllElements('ClickThrough')
          .map((e) => e.innerText.trim())
          .toList();

      final clickTrackingUrls = document
          .findAllElements('ClickTracking')
          .map((e) => e.innerText.trim())
          .toList();

      // Parse skip duration from <Linear skipoffset="..."> if available
      int? vastSkipDuration;
      final Iterable<XmlElement> linearElements =
          document.findAllElements('Linear').where(
                (e) => e.getAttribute('skipoffset') != null,
              );
      final XmlElement? linear =
          linearElements.isNotEmpty ? linearElements.first : null;
      final skipOffset = linear?.getAttribute('skipoffset');
      if (skipOffset != null) {
        final parts = skipOffset.split(':');
        if (parts.length == 3) {
          final h = int.tryParse(parts[0]) ?? 0;
          final m = int.tryParse(parts[1]) ?? 0;
          final s = int.tryParse(parts[2]) ?? 0;
          vastSkipDuration = h * 3600 + m * 60 + s;
        } else if (parts.length == 1) {
          vastSkipDuration = int.tryParse(skipOffset);
        }
      }

      List<OverlayAd> parsedOverlayAds = [];

      for (final creative in document.findAllElements('Creative')) {
        for (final nonLinear in creative.findAllElements('NonLinear')) {
          final staticResource = nonLinear
              .findElements('StaticResource')
              .map((e) => e.innerText.trim())
              .firstWhere((e) => e.isNotEmpty, orElse: () => '');

          if (staticResource.isEmpty) continue;

          final clickThrough = nonLinear
              .findElements('NonLinearClickThrough')
              .map((e) => e.innerText.trim())
              .firstWhere((e) => e.isNotEmpty, orElse: () => '');

          final minSuggestedDuration =
              nonLinear.getAttribute('minSuggestedDuration') ?? '00:00:05';

          int duration = 10;
          final parts = minSuggestedDuration.split(':');
          if (parts.length == 3) {
            final h = int.tryParse(parts[0]) ?? 0;
            final m = int.tryParse(parts[1]) ?? 0;
            final s = int.tryParse(parts[2]) ?? 0;
            duration = h * 3600 + m * 60 + s;
          }

          int startTime = 10;
          final startTimeAttr = nonLinear.getAttribute('startTime') ??
              nonLinear.getAttribute('start') ??
              creative.getAttribute('sequence');
          if (startTimeAttr != null) {
            final parsed = int.tryParse(startTimeAttr);
            if (parsed != null && parsed > 0) {
              startTime = parsed;
            }
          }

          parsedOverlayAds.add(OverlayAd(
            imageUrl: staticResource,
            clickThroughUrl: clickThrough,
            startTime: startTime,
            duration: duration,
          ));
        }
      }

      final skipDuration = vastSkipDuration;

      return VastMedia(
        mediaUrls: mediaUrls,
        clickThroughUrls: clickThroughUrls,
        clickTrackingUrls: clickTrackingUrls,
        skipDuration: skipDuration,
        overlayAds: parsedOverlayAds,
      );
    } catch (e, st) {
      log('VAST parsing error: $e\n$st');
      return null;
    }
  }

  String formatSecondsToHMS(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
  }

  /// Monitor x265 video performance
  void _monitorX265Performance(Duration position, Duration duration) {
    final isX265Video =
        videoUrlType.value.toLowerCase() == PlayerTypes.x265.toLowerCase();
    if (!isX265Video) return;

    final currentSecond = position.inSeconds;
    final totalSeconds = duration.inSeconds;

    if (currentSecond > 0 && currentSecond % 30 == 0) {
      final progress = totalSeconds > 0
          ? (currentSecond / totalSeconds * 100).toStringAsFixed(1)
          : '0.0';
      log('+-+-+-+-+-+-+-+-+-x265 Performance: ${formatSecondsToHMS(currentSecond)}/${formatSecondsToHMS(totalSeconds)} ($progress%) - Playing: ${isVideoPlaying.value}, Buffering: ${isBuffering.value}');

      // Check for performance issues
      if (isBuffering.value && currentSecond > 10) {
        log('+-+-+-+-+-+-+-+-+-x265 Warning: Video is buffering after 10 seconds, possible performance issue');
      }
    }

    if (currentSecond == 0 &&
        duration > Duration.zero &&
        !isBuffering.value &&
        !hasAttemptedForcePlay) {
      log('+-+-+-+-+-+-+-+-+-x265 Warning: Video appears stuck at 0 seconds, duration available: $duration');
      if (podPlayerController.value.isInitialised) {
        log('+-+-+-+-+-+-+-+-+-x265 Attempting to force play stuck video');
        hasAttemptedForcePlay = true;
        podPlayerController.value.play();

        Future.delayed(Duration(seconds: 2), () {
          if (podPlayerController.value.isVideoPlaying) {
            log('+-+-+-+-+-+-+-+-+-x265 Force play successful!');
          } else {
            log('+-+-+-+-+-+-+-+-+-x265 Force play failed, video still not playing');
          }
        });
      }
    }
  }

  int parseDurationToSeconds(String? duration) {
    if (duration == null || duration.isEmpty) return 0;
    final parts = duration.split(':').map((e) => int.tryParse(e) ?? 0).toList();
    if (parts.length == 3) {
      // hh:mm:ss
      return parts[0] * 3600 + parts[1] * 60 + parts[2];
    } else if (parts.length == 2) {
      // mm:ss
      return parts[0] * 60 + parts[1];
    } else if (parts.length == 1) {
      // ss
      return parts[0];
    }
    return 0;
  }

  //-------------------------------------------------------------------------------
  // Video Player Related Methods
  //-------------------------------------------------------------------------------

  void setInitialFocusesForSubtitleAndQuality() {
    // Only add default_quality if it doesn't already exist in the list
    final hasDefaultQuality = videoQualities.any((link) =>
        link.quality.isEmpty ||
        link.quality.toLowerCase() ==
            QualityConstants.defaultQuality.toLowerCase());

    if (!hasDefaultQuality) {
      videoQualities.add(VideoData(
          id: -1,
          quality: QualityConstants.defaultQuality,
          url: videoUrl.value,
          urlType: videoUrlType.value));
    }

    /// Initialize subtitles from the initial model
    subtitleList.clear();
    if (videoModel.value.subtitleList.isNotEmpty) {
      subtitleList.addAll(videoModel.value.subtitleList);
      subtitleList.insert(
          0,
          SubtitleModel(
              id: -1, language: locale.value.off.capitalizeEachWord()));

      // Load default subtitle if available
      if (subtitleList
          .any((element) => element.isDefaultLanguage.getBoolInt())) {
        selectedSubtitleModel(subtitleList
            .firstWhere((element) => element.isDefaultLanguage.getBoolInt()));
        loadSubtitles(selectedSubtitleModel.value);
      }
    } else {
      subtitleList.add(SubtitleModel(
          id: -1, language: locale.value.off.capitalizeEachWord()));
    }
  }

  (String, String) getVideoLinkAndType() {
    if (isTrailer.value) {
      log('+-+-+-+-+-+-+-+-+-getVideoLinkAndType: Trailer mode - checking for trailer URL');
      log('+-+-+-+-+-+-+-+-+-trailerData.length: ${videoModel.value.trailerData.length}');
      log('+-+-+-+-+-+-+-+-+-trailerUrl: ${videoModel.value.trailerUrl}');
      log('+-+-+-+-+-+-+-+-+-trailerUrlType: ${videoModel.value.trailerUrlType}');

      // First priority: Check trailerData list (most reliable)
      if (videoModel.value.trailerData.isNotEmpty) {
        final trailer = videoModel.value.trailerData
                .firstWhereOrNull((v) => v.url.isNotEmpty) ??
            videoModel.value.trailerData.first;
        if (trailer.url.isNotEmpty) {
          log('+-+-+-+-+-+-+-+-+-Found trailer URL in trailerData: type=${trailer.urlType}, url=${trailer.url.substring(0, trailer.url.length > 100 ? 100 : trailer.url.length)}...');
          return (trailer.urlType, trailer.url);
        }
      }

      // Second priority: Check trailerUrl from ContentData (extension getter returns non-nullable String)
      final tType = videoModel.value.trailerUrlType;
      final tUrl = videoModel.value.trailerUrl;
      if (tType.isNotEmpty && tUrl.isNotEmpty) {
        log('+-+-+-+-+-+-+-+-+-Found trailer URL in trailerUrl: type=$tType, url=${tUrl.substring(0, tUrl.length > 100 ? 100 : tUrl.length)}...');
        return (tType, tUrl);
      }

      // Fallback: Use first playable quality (should not happen for trailers)
      if (videoModel.value.videoQualities.isNotEmpty) {
        log('+-+-+-+-+-+-+-+-+-WARNING: No trailer URL found, using first video quality as fallback');
        final first = videoModel.value.videoQualities
                .firstWhereOrNull((v) => v.url.isNotEmpty) ??
            videoModel.value.videoQualities.first;
        return (first.urlType, first.url);
      }

      log('+-+-+-+-+-+-+-+-+-ERROR: No trailer URL found anywhere!');
      return (videoUrlType.value, videoUrl.value);
    } else if (liveShowModel.id > 0) {
      if (liveShowModel.streamType.toLowerCase() ==
          PlayerTypes.embedded.toLowerCase()) {
        return (liveShowModel.streamType, liveShowModel.embedded);
      }
      return (liveShowModel.streamType, liveShowModel.serverUrl);
    } else if (videoModel.value.videoUploadType.toLowerCase() ==
        PlayerTypes.embedded.toLowerCase()) {
      return (videoModel.value.videoUploadType, videoModel.value.videoUrlInput);
    } else {
      // If no specific quality is selected, prefer default_quality
      if (videoModel.value.isDefaultQualityAvailable) {
        final defaultQuality = videoModel.value.defaultQuality;
        if (defaultQuality.url.isNotEmpty &&
            defaultQuality.urlType.isNotEmpty) {
          log('+-+-+-+-+-+-+-+-+-Using default_quality: type=${defaultQuality.urlType}, url=${defaultQuality.url.substring(0, defaultQuality.url.length > 100 ? 100 : defaultQuality.url.length)}...');
          return (defaultQuality.urlType, defaultQuality.url);
        }
      }

      return (videoModel.value.videoUploadType.trim().isEmpty &&
              videoModel.value.videoUrlInput.trim().isEmpty
          ? (videoUrlType.value, videoUrl.value)
          : (videoModel.value.videoUploadType, videoModel.value.videoUrlInput));
    }
  }

  Future<void> initializePlayer() async {
    bool isResumingFromContinueWatch =
        isAlreadyStartedWatching(videoModel.value.watchedTime);

    // Don't disable trailer mode if we're explicitly in trailer mode
    // Only disable if we're resuming from continue watch (user wants to continue, not watch trailer)
    if (!isTrailer.value &&
        ((videoModel.value.type == VideoType.video ||
                videoModel.value.type == VideoType.liveTv) ||
            isResumingFromContinueWatch)) {
      isTrailer(false);
    }

    log('+-+-+-+-+-+-+-+-+-initializePlayer: isTrailer=${isTrailer.value}, isResumingFromContinueWatch=$isResumingFromContinueWatch');

    if (!isTrailer.value && !isResumingFromAd.value && preRollAds.isNotEmpty) {
      log('+-+-+-+-+-+-+-+-+-Playing pre-roll ads before initializing video player');
      for (int i = 0; i < preRollAds.length; i++) {
        log('+-+-+-+-+-+-+-+-+-Playing pre-roll ad ${i + 1}/${preRollAds.length}: ${preRollAds[i].url}');
        await playAd(preRollAds[i]);
        log('+-+-+-+-+-+-+-+-+-Pre-roll ad ${i + 1} completed');
      }
      log('+-+-+-+-+-+-+-+-+-All pre-roll ads completed, now initializing video player');
    }

    isPostRollAdShown.value = false;
    shownMidRollAds.clear();
    shownOverlayAds.clear();
    currentAdIndex.value = 0;

    (String, String) videoLinkType = getVideoLinkAndType();
    videoUrlType(videoLinkType.$1);
    videoUrl(videoLinkType.$2);
    uniqueKey = UniqueKey();

    log('+-+-+-+-+-+-+-+-+-initializePlayer: videoUrlType=${videoUrlType.value}, videoUrl=${videoUrl.value.substring(0, videoUrl.value.length > 100 ? 100 : videoUrl.value.length)}...');

    if (videoUrlType.value.toLowerCase() == PlayerTypes.local.toLowerCase()) {
      log('+-+-+-+-+-+-+-+-+-Local video detected in initializePlayer');
      log('+-+-+-+-+-+-+-+-+-Video URL: ${videoUrl.value}');
    }

    // For trailers, if URL is empty, try harder to get it from trailerData
    if (isTrailer.value &&
        (videoUrl.value.isEmpty || videoUrlType.value.isEmpty)) {
      log('+-+-+-+-+-+-+-+-+-Trailer URL empty, checking trailerData...');
      if (videoModel.value.trailerData.isNotEmpty) {
        log('+-+-+-+-+-+-+-+-+-trailerData has ${videoModel.value.trailerData.length} items');
        for (var i = 0; i < videoModel.value.trailerData.length; i++) {
          final trailer = videoModel.value.trailerData[i];
          log('+-+-+-+-+-+-+-+-+-Checking trailer[$i]: url=${trailer.url}, type=${trailer.urlType}');
        }
        final trailer = videoModel.value.trailerData
                .firstWhereOrNull((v) => v.url.isNotEmpty) ??
            videoModel.value.trailerData.first;
        if (trailer.url.isNotEmpty) {
          log('+-+-+-+-+-+-+-+-+-Found trailer URL in trailerData: ${trailer.url.substring(0, trailer.url.length > 100 ? 100 : trailer.url.length)}..., type=${trailer.urlType}');
          videoUrl(trailer.url);
          videoUrlType(trailer.urlType);
        } else {
          log('+-+-+-+-+-+-+-+-+-WARNING: Trailer data exists but all URLs are empty!');
        }
      } else {
        log('+-+-+-+-+-+-+-+-+-WARNING: trailerData is empty, checking trailerUrl...');
        // Try trailerUrl from ContentData (extension getter returns non-nullable String)
        final trailerUrl = videoModel.value.trailerUrl;
        final trailerUrlType = videoModel.value.trailerUrlType;
        if (trailerUrl.isNotEmpty && trailerUrlType.isNotEmpty) {
          log('+-+-+-+-+-+-+-+-+-Found trailerUrl: ${trailerUrl.substring(0, trailerUrl.length > 100 ? 100 : trailerUrl.length)}..., type=$trailerUrlType');
          videoUrl(trailerUrl);
          videoUrlType(trailerUrlType);
        } else {
          log('+-+-+-+-+-+-+-+-+-ERROR: No trailer URL found anywhere! Deferring initialization...');
        }
      }
    }

    // If we don't yet have a URL/type (e.g., qualities not loaded yet), wait for onAddVideoQuality
    if (videoUrl.value.isEmpty || videoUrlType.value.isEmpty) {
      log('+-+-+-+-+-+-+-+-+-initializePlayer deferred: waiting for qualities/subtitle data (isTrailer=${isTrailer.value})');
      isInitializingPlayer(false);
      isBuffering(false);
      return;
    }

    if (videoUrl.isNotEmpty && videoUrlType.isNotEmpty) {
      if (videoUrlType.value.toLowerCase() ==
          PlayerTypes.youtube.toLowerCase()) {
        await initializeYoutubePlayer();
      } else if (videoLinkType.$1.toLowerCase() ==
              PlayerTypes.embedded.toLowerCase() ||
          videoUrlType.value.toLowerCase() == PlayerTypes.vimeo.toLowerCase()) {
        String url = videoUrl.value;
        if (videoUrlType.value.toLowerCase() ==
            PlayerTypes.vimeo.toLowerCase()) {
          url = "https://vimeo.com/${url.split("/").last}";
          initializeWebViewPlayer(url);
        } else if (videoUrlType.value.toLowerCase() ==
            PlayerTypes.embedded.toLowerCase()) {
          initializeWebViewPlayer(movieEmbedCode(videoUrl.value));
        }
      } else if (videoUrlType.value.toLowerCase() ==
              PlayerTypes.url.toLowerCase() ||
          videoUrlType.value.toLowerCase() == PlayerTypes.hls.toLowerCase() ||
          videoUrlType.value.toLowerCase() == PlayerTypes.local.toLowerCase() ||
          videoUrlType.value.toLowerCase() == PlayerTypes.x265.toLowerCase()) {
        await initializePodPlayer(videoUrl.value);
      }
    }
  }

  //region Video Player Initialization
  Future<void> initializeYoutubePlayer() async {
    isLoading(true);

    YoutubePlayerController youtubeController = YoutubePlayerController(
      initialVideoId: videoUrl.value.getYouTubeId(),
      flags: YoutubePlayerFlags(
        autoPlay: isTrailer.value
            ? true
            : isAutoPlay.value, // Always auto-play for trailers
        enableCaption: false,
        hideControls: true,
        isLive: getVideoLinkAndType().$1.toLowerCase() ==
            PlayerTypes.hls.toLowerCase(),
      ),
    );

    disposeControllers();

    youtubePlayerController(youtubeController);

    // For trailers, ensure playback starts
    if (isTrailer.value) {
      log('+-+-+-+-+-+-+-+-+-Setting up YouTube trailer auto-play');
      // Don't call continueWatch for trailers - start from beginning
      Future.delayed(Duration(milliseconds: 500), () {
        if (youtubeController.value.isReady) {
          log('+-+-+-+-+-+-+-+-+-YouTube controller is ready, starting playback');
          youtubePlayerController.value.play();
          isVideoPlaying(youtubePlayerController.value.value.isPlaying);
          isLoading(false);
          log('+-+-+-+-+-+-+-+-+-YouTube trailer playback started, isPlaying=${youtubePlayerController.value.value.isPlaying}');
        } else {
          log('+-+-+-+-+-+-+-+-+-YouTube controller not ready yet, waiting...');
          // If not ready yet, wait a bit more
          Future.delayed(Duration(milliseconds: 1000), () {
            if (youtubeController.value.isReady) {
              log('+-+-+-+-+-+-+-+-+-YouTube controller ready (delayed), starting playback');
              youtubePlayerController.value.play();
              isVideoPlaying(youtubePlayerController.value.value.isPlaying);
              isLoading(false);
              log('+-+-+-+-+-+-+-+-+-YouTube trailer playback started (delayed), isPlaying=${youtubePlayerController.value.value.isPlaying}');
            } else {
              log('+-+-+-+-+-+-+-+-+-WARNING: YouTube controller still not ready after delay');
              isLoading(false);
            }
          });
        }
      });
    } else if (youtubeController.value.isReady) {
      youtubePlayerController.value.play();
      isVideoPlaying(youtubePlayerController.value.value.isPlaying);
      isLoading(false);
    } else {
      // If not ready, set up a listener
      youtubeController.addListener(() {
        if (youtubeController.value.isReady && !isVideoPlaying.value) {
          youtubePlayerController.value.play();
          isVideoPlaying(youtubePlayerController.value.value.isPlaying);
          isLoading(false);
        }
      });
    }
    if (midRollAds.isNotEmpty &&
        youtubeController.value.metaData.duration > Duration.zero) {
      calculateMidRollTimes(youtubeController.value.metaData.duration);
    }
  }

  //pod player
  Future<void> initializePodPlayer(String url) async {
    if (_isCurrentlyInitializing) {
      log('+-+-+-+-+-+-+-+-+-Already initializing, skipping duplicate call');
      return;
    }

    try {
      _isCurrentlyInitializing = true;
      isBuffering(true);
      isInitializingPlayer(true);

      final videoSource =
          getVideoPlatform(type: videoUrlType.value, videoURL: url);
      final isX265Video =
          videoUrlType.value.toLowerCase() == PlayerTypes.x265.toLowerCase();
      final isLocalVideo =
          videoUrlType.value.toLowerCase() == PlayerTypes.local.toLowerCase();

      if (isLocalVideo) {
        log("+-+-+-+-+-+-+-+-+-Local video initialization:");
        log("+-+-+-+-+-+-+-+-+-URL: $url");
        log("+-+-+-+-+-+-+-+-+-Type: ${videoUrlType.value}");
        log("+-+-+-+-+-+-+-+-+-Is Resuming From Ad: ${isResumingFromAd.value}");
      }

      if (isX265Video) {
        hasAttemptedForcePlay = false;
        hasAttemptedReinitialize = false;
      }

      final podConfig = PodPlayerConfig(
        autoPlay: isTrailer.value, // Auto-play for trailers
        isLooping: false,
        forcedVideoFocus: true,
        wakelockEnabled: true,
        videoQualityPriority: availableQualities,
      );

      final controller = PodPlayerController(
        podPlayerConfig: podConfig,
        playVideoFrom: videoSource,
      );

      await controller.initialise().then((_) {
        log('+-+-+-+-+-+-+-+-+-Controller initialized successfully');
        isInitializingPlayer(false);

        // Reset ad tracking states
        isPostRollAdShown.value = false;
        shownMidRollAds.clear();
        shownOverlayAds.clear();

        if (midRollAds.isNotEmpty &&
            controller.totalVideoLength > Duration.zero) {
          calculateMidRollTimes(controller.totalVideoLength);
        }

        // For trailers, don't seek to watched time - start from beginning
        if (!isTrailer.value &&
            videoModel.value.watchedTime.isNotEmpty &&
            !isResumingFromAd.value) {
          try {
            final seekPosition =
                getWatchedTimeInDuration(videoModel.value.watchedTime);
            controller.videoSeekForward(seekPosition);
          } catch (e) {
            log("Error parsing continueWatchDuration: ${e.toString()}");
          }
        } else if (isTrailer.value) {
          log('+-+-+-+-+-+-+-+-+-Trailer mode: Starting from beginning (not seeking to watched time)');
        }

        disposeControllers();

        // CRITICAL: Assign controller FIRST before any UI updates
        podPlayerController(controller);

        // Force UI refresh to ensure widget tree rebuilds with new controller
        uniqueKey = UniqueKey();
        uniqueProgressBarKey = UniqueKey();
        update();

        log('+-+-+-+-+-+-+-+-+-UI updated with new controller');

        // Handle different video types
        if (isLocalVideo) {
          _handleLocalVideoPlayback(controller);
        } else if (videoUrlType.value.toLowerCase() ==
            PlayerTypes.hls.toLowerCase()) {
          _handleHLSVideoPlayback(controller);
        } else if (isX265Video) {
          _handleX265VideoPlayback(controller);
        } else {
          // Standard playback - for trailers, ensure auto-play works
          if (isTrailer.value) {
            log('+-+-+-+-+-+-+-+-+-Starting trailer playback (PodPlayer)');
            Future.delayed(Duration(milliseconds: 300), () {
              isBuffering(false);
              controller.play();
              // Verify trailer is playing
              Future.delayed(Duration(milliseconds: 500), () {
                if (!controller.isVideoPlaying) {
                  log('+-+-+-+-+-+-+-+-+-Trailer not playing, retrying...');
                  controller.play();
                } else {
                  log('+-+-+-+-+-+-+-+-+-Trailer playing successfully (PodPlayer)');
                }
              });
            });
          } else {
            Future.delayed(Duration(milliseconds: 300), () {
              isBuffering(false);
              controller.play();
            });
          }
        }

        showProgressBar();
      }).catchError((error, stackTrace) {
        isInitializingPlayer(false);
        isBuffering(false);
        log("Error during initialization: ${error.toString()}");
        _handleInitializationError(error, isX265Video, isLocalVideo);
      });

      listenVideoEvent();
    } catch (e) {
      isInitializingPlayer(false);
      isBuffering(false);
      log("Exception during initialization: ${e.toString()}");
    } finally {
      _isCurrentlyInitializing = false;
    }
  }

  void _handleLocalVideoPlayback(PodPlayerController controller) {
    log('+-+-+-+-+-+-+-+-+-Setting up Local video playback');

    // Wait for UI to rebuild and video surface to be ready
    Future.delayed(Duration(milliseconds: 600), () {
      if (!controller.isInitialised) {
        log('+-+-+-+-+-+-+-+-+-ERROR: Controller not initialized');
        return;
      }

      log('+-+-+-+-+-+-+-+-+-Starting Local video playback');
      isBuffering(false);
      controller.play();

      // Verify playback started
      Future.delayed(Duration(milliseconds: 1200), () {
        final isPlaying = controller.isVideoPlaying;
        log('+-+-+-+-+-+-+-+-+-Local video status: isPlaying=$isPlaying');

        if (!isPlaying) {
          log('+-+-+-+-+-+-+-+-+-Local video not playing, attempting recovery');

          // Force UI refresh
          uniqueKey = UniqueKey();
          update();

          // Retry play after refresh
          Future.delayed(Duration(milliseconds: 400), () {
            log('+-+-+-+-+-+-+-+-+-Retry play after UI refresh');
            controller.play();

            // Final verification
            Future.delayed(Duration(milliseconds: 600), () {
              if (controller.isVideoPlaying) {
                log('+-+-+-+-+-+-+-+-+-Local video playing after retry ✓');
                isBuffering(false);
              } else {
                log('+-+-+-+-+-+-+-+-+-ERROR: Local video failed to play');
                isBuffering(false);
                errorMessage.value =
                    'Unable to play local video. Please try again.';
              }
            });
          });
        } else {
          log('+-+-+-+-+-+-+-+-+-Local video playing successfully ✓');
        }
      });
    });
  }

  void _handleHLSVideoPlayback(PodPlayerController controller) {
    isBuffering(false);
    Future.delayed(Duration(milliseconds: 200), () {
      controller.play();
      Future.delayed(Duration(milliseconds: 500), () {
        if (!controller.isVideoPlaying && !isBuffering.value) {
          controller.play();
          Future.delayed(Duration(seconds: 1), () {
            if (!controller.isVideoPlaying) {
              controller.play();
              Future.delayed(Duration(seconds: 2), () {
                if (!controller.isVideoPlaying) {
                  forceRefreshHLSPlayer();
                }
              });
            }
          });
        } else {
          forceHLSDisplayRefresh();
        }
      });
    });
  }

  void _handleX265VideoPlayback(PodPlayerController controller) {
    isBuffering(false);
    Future.delayed(Duration(seconds: 3), () {
      if (!controller.isVideoPlaying && !isBuffering.value) {
        controller.play();
        Future.delayed(Duration(seconds: 2), () {
          if (!controller.isVideoPlaying) {
            controller.play();
          }
        });
      }
    });
  }

  void _handleInitializationError(
      dynamic error, bool isX265Video, bool isLocalVideo) {
    final errorText = error.toString().toLowerCase();

    if (isX265Video) {
      if (errorText.contains('unrecognizedinputformat') ||
          errorText.contains('source error') ||
          errorText.contains('exoplaybackexception') ||
          errorText.contains('codec') ||
          errorText.contains('decode')) {
        errorMessage.value =
            'This x265 video format is not supported on this device.';
      } else {
        errorMessage.value =
            'Failed to load x265 video. Please check your connection.';
      }
    } else if (isLocalVideo) {
      if (errorText.contains('file') ||
          errorText.contains('path') ||
          errorText.contains('not found')) {
        errorMessage.value = 'Local video file not found or inaccessible.';
      } else {
        errorMessage.value =
            'Failed to load local video file. Please try again.';
      }
    }
  }

  //webview
  Future<void> initializeWebViewPlayer(String url) async {
    isBuffering(true);
    playNextVideo(false);
    // Remove any existing video channel listener to avoid duplicates
    removeVideoChannelListener();

    //initialize the WebViewController with the provided URL
    final embedHtml = movieEmbedCode(url);
    webViewController.value = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 10; SM-G973F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            log('+-+-+-+-+-+-+-+-+-WebView page finished loading: $url');
            isBuffering(false);
            showProgressBar();
            listenVideoEvent();

            // For Vimeo, try to inject some JavaScript to help with initialization
            if (videoUrlType.value.toLowerCase() ==
                PlayerTypes.vimeo.toLowerCase()) {
              _injectVimeoHelperScript();
            }

            // For trailers, ensure auto-play works in WebView
            if (isTrailer.value) {
              log('+-+-+-+-+-+-+-+-+-Enabling auto-play for trailer in WebView');
              Future.delayed(Duration(milliseconds: 500), () {
                webViewController.value.runJavaScript('''
                  try {
                    var videos = document.querySelectorAll('video');
                    if (videos.length > 0) {
                      videos[0].play();
                    }
                    var iframes = document.querySelectorAll('iframe');
                    iframes.forEach(function(iframe) {
                      try {
                        iframe.contentWindow.postMessage('{"event":"command","func":"playVideo","args":""}', '*');
                      } catch(e) {}
                    });
                  } catch(e) {
                    console.log('Auto-play error: ' + e);
                  }
                ''');
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            log('+-+-+-+-+-+-+-+-+-WebView resource error: ${error.description}');
            isBuffering(false);
            handleError(error.description);
          },
          onPageStarted: (url) {
            log('+-+-+-+-+-+-+-+-+-WebView page started loading: $url');
            isVideoPlaying(true);
          },
          onNavigationRequest: (NavigationRequest request) {
            log('+-+-+-+-+-+-+-+-+-WebView navigation request: ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'VideoChannel',
        onMessageReceived: (message) {
          try {
            final decoded = jsonDecode(message.message);

            if (decoded['event'] == 'timeUpdate') {
              final int current =
                  decoded['currentTime'].toString().toDouble().toInt();
              final int total =
                  decoded['duration'].toString().toDouble().toInt();
              final position = Duration(seconds: current);
              final duration = Duration(seconds: total);

              if (duration > Duration.zero &&
                  midRollAds.isNotEmpty &&
                  midRollAdSeconds.isEmpty) {
                calculateMidRollTimes(duration);
              }
              _checkAndPlayAdsAtPosition(position);

              currentVideoTotalDuration(duration);
              currentVideoPosition(position);
              playNextVideo(((total - current) < 30 && total > 30));
              if (!showSkipIntroOverlay.value) showSkipIntroButton();

              if (!isTrailer.value) {
                final subtitle = availableSubtitleList.firstWhereOrNull((s) =>
                    s.start.inSeconds <= current && s.end.inSeconds >= current);
                if (subtitle != null &&
                    subtitle.data != currentSubtitle.value) {
                  currentSubtitle(subtitle.data);
                } else if (subtitle == null &&
                    currentSubtitle.value.isNotEmpty) {
                  currentSubtitle('');
                }
              }
            } else if (decoded['event'] == 'qualityChanged') {
              // Handle quality change from WebView
              currentQuality(decoded['quality'] ??
                  QualityConstants.defaultQuality.toLowerCase());
            } else if (decoded['event'] == 'subtitleChanged') {
              // Handle subtitle change from WebView
              final subtitleId = decoded['subtitleId'];
              if (subtitleId != null) {
                final selectedSubtitle = subtitleList
                    .firstWhereOrNull((s) => s.id.toString() == subtitleId);
                if (selectedSubtitle != null) {
                  selectedSubtitleModel(selectedSubtitle);
                  loadSubtitles(selectedSubtitle);
                }
              }
            }
          } catch (e) {
            switch (message.message) {
              case 'ready':
                playNextVideo(false);
                isLoading(false);
                // Send available qualities and subtitles to WebView
                sendVideoDataToWebView();
                break;
              case 'playing':
                isVideoPlaying(true);
                break;
              case 'paused':
                isVideoPlaying(false);
                break;
              case 'ended':
                isVideoCompleted(true);
                isBuffering(false);
                isLoading(false);
                if (isTrailer.value) {
                  onVideoChange?.call();
                }
                break;
              case 'seeking':
                isBuffering(true);
                break;
              case 'seeked':
                isBuffering(false);
                break;
            }
          }
        },
      );

    if (videoUrlType.value.toLowerCase() == PlayerTypes.vimeo.toLowerCase()) {
      webViewController.value.loadRequest(
        Uri.parse(url),
        headers: {
          'Referer': DOMAIN_URL,
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 10; SM-G973F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.5',
          'Accept-Encoding': 'gzip, deflate',
          'Connection': 'keep-alive',
        },
      );
    } else {
      webViewController.value.loadHtmlString(embedHtml, baseUrl: DOMAIN_URL);
    }
    update();
  }

  // Send video data (qualities, subtitles) to WebView
  void sendVideoDataToWebView() {
    try {
      final videoData = {
        'qualities': videoQualities
            .map((q) => {
                  'id': q.id,
                  'quality': q.quality,
                  'url': q.url,
                  'type': q.urlType,
                })
            .toList(),
        'subtitles': subtitleList
            .map((s) => {
                  'id': s.id,
                  'language': s.language,
                  'subtitleFile': s.subtitleFile,
                  'isDefaultLanguage': s.isDefaultLanguage.getBoolInt(),
                })
            .toList(),
        'currentQuality': currentQuality.value,
        'currentSubtitle': selectedSubtitleModel.value.id,
      };

      webViewController.value
          .runJavaScript('window.postMessage(${jsonEncode(videoData)}, "*");');
    } catch (e) {
      log("Error sending video data to WebView: $e");
    }
  }

  // Check if WebView is currently active
  bool isWebViewActive() {
    return videoUrlType.value.toLowerCase() ==
            PlayerTypes.embedded.toLowerCase() ||
        videoUrlType.value.toLowerCase() == PlayerTypes.vimeo.toLowerCase();
  }

  void removeVideoChannelListener() {
    try {
      webViewController.value.removeJavaScriptChannel('VideoChannel');
    } catch (e) {
      log("Error removing JavaScript channel: $e");
    }
  }

  void _injectVimeoHelperScript() {
    try {
      webViewController.value.runJavaScript('''
        console.log('+-+-+-+-+-+-+-+-+-Vimeo helper script injected');
        
        // Function to create and embed Vimeo player iframe
        function embedVimeoPlayer() {
          const videoId = window.location.pathname.split('/').pop();
          console.log('+-+-+-+-+-+-+-+-+-Extracted Vimeo video ID:', videoId);
          
          if (videoId && !document.querySelector('iframe[src*="player.vimeo.com"]')) {
            // Create iframe for Vimeo player
            const iframe = document.createElement('iframe');
            iframe.src = 'https://player.vimeo.com/video/' + videoId + '?autoplay=1&loop=0&byline=0&portrait=0&title=0&background=0&transparent=0';
            iframe.width = '100%';
            iframe.height = '100%';
            iframe.style.border = 'none';
            iframe.style.position = 'absolute';
            iframe.style.top = '0';
            iframe.style.left = '0';
            iframe.allowFullscreen = true;
            iframe.allow = 'autoplay; fullscreen; picture-in-picture';
            
            // Clear existing content and add iframe
            document.body.innerHTML = '';
            document.body.appendChild(iframe);
            
            console.log('+-+-+-+-+-+-+-+-+-Vimeo iframe created and embedded');
            
            // Set up message listener for Vimeo player events
            iframe.addEventListener('load', function() {
              console.log('+-+-+-+-+-+-+-+-+-Vimeo iframe loaded');
              
              // Send ready message to Flutter
              try {
                if (window.VideoChannel) {
                  VideoChannel.postMessage('ready');
                }
              } catch (e) {
                console.log('+-+-+-+-+-+-+-+-+-Could not send ready message:', e);
              }
            });
            
            // Listen for messages from Vimeo player
            window.addEventListener('message', function(event) {
              if (event.origin !== 'https://player.vimeo.com') return;
              
              const data = event.data;
              console.log('+-+-+-+-+-+-+-+-+-Vimeo player message:', data);
              
              try {
                if (typeof data === 'string') {
                  const parsedData = JSON.parse(data);
                  
                  if (parsedData.method === 'ready') {
                    console.log('+-+-+-+-+-+-+-+-+-Vimeo player ready');
                    if (window.VideoChannel) {
                      VideoChannel.postMessage('ready');
                    }
                  } else if (parsedData.method === 'playProgress') {
                    const currentTime = Math.floor(parsedData.data.seconds);
                    const duration = Math.floor(parsedData.data.duration);
                    
                    if (window.VideoChannel) {
                      VideoChannel.postMessage(JSON.stringify({
                        event: 'timeUpdate',
                        currentTime: currentTime,
                        duration: duration
                      }));
                    }
                  } else if (parsedData.method === 'play') {
                    console.log('+-+-+-+-+-+-+-+-+-Vimeo player started');
                    if (window.VideoChannel) {
                      VideoChannel.postMessage('playing');
                    }
                  } else if (parsedData.method === 'pause') {
                    console.log('+-+-+-+-+-+-+-+-+-Vimeo player paused');
                    if (window.VideoChannel) {
                      VideoChannel.postMessage('paused');
                    }
                  } else if (parsedData.method === 'ended') {
                    console.log('+-+-+-+-+-+-+-+-+-Vimeo player ended');
                    if (window.VideoChannel) {
                      VideoChannel.postMessage('ended');
                    }
                  }
                }
              } catch (e) {
                console.log('+-+-+-+-+-+-+-+-+-Error parsing Vimeo message:', e);
              }
            });
            
            return true;
          }
          return false;
        }
        
        // Try to embed immediately
        if (!embedVimeoPlayer()) {
          // If not successful, try again after a delay
          setTimeout(function() {
            console.log('+-+-+-+-+-+-+-+-+-Retrying Vimeo embed...');
            embedVimeoPlayer();
          }, 1000);
        }
      ''');
    } catch (e) {
      log('+-+-+-+-+-+-+-+-+-Error injecting Vimeo helper script: $e');
    }
  }

  //endregion (MediaKit removed)

  void continueWatch() {
    if (videoModel.value.watchedTime.isNotEmpty &&
        videoModel.value.watchedTime != '00:00:00') {
      try {
        final parts = videoModel.value.watchedTime.split(':');
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);
        final seconds = int.parse(parts[2]);
        final seekPosition =
            Duration(hours: hours, minutes: minutes, seconds: seconds);

        if (podPlayerController.value.isInitialised) {
          podPlayerController.value.videoSeekForward(seekPosition);
        } else if (isWebViewActive()) {
          // handled below
        } else if (youtubePlayerController.value.value.hasPlayed) {
          youtubePlayerController.value.seekTo(seekPosition);
        } else if (isWebViewActive()) {
          // WebView seek to position
          final seekSeconds = seekPosition.inSeconds;
          webViewController.value
              .runJavaScript('const video = document.querySelector("video"); '
                  'if (video) { video.currentTime = $seekSeconds; }');
        } else {
          log("Video not initialized or not playing");
        }
      } catch (e) {
        log("Error parsing continueWatchDuration: ${e.toString()}");
      }
    }
  }

  void checkIfVideoEnded() {
    final position = getVideoCurrentPosition();
    if (Get.isRegistered<TvShowPreviewController>()) {
      final tvShowPreviewCont = Get.find<TvShowPreviewController>();
      hasNextVideo(tvShowPreviewCont.seasonIdWiseEpisodeList[
                  tvShowPreviewCont.selectSeason.value.seasonId] !=
              null &&
          tvShowPreviewCont.currentEpisodeIndex.value <
              (tvShowPreviewCont
                      .seasonIdWiseEpisodeList[
                          tvShowPreviewCont.selectSeason.value.seasonId]!
                      .length -
                  1));
    }
    if (podPlayerController.value.videoPlayerValue != null) {
      podPlayerController.value.videoPlayerValue!.position;
      final duration = podPlayerController.value.videoPlayerValue!.duration;

      final remaining = duration - position;
      final threshold = duration.inSeconds * 0.20;
      playNextVideo(remaining.inSeconds <= threshold);
      if (podPlayerController.value.isInitialised) {
        if (!isTrailer.value) {
          final subtitle = availableSubtitleList.firstWhereOrNull(
              (s) => s.start <= position && s.end >= position);
          if (subtitle != null && subtitle.data != currentSubtitle.value) {
            currentSubtitle(subtitle.data);
          } else if (subtitle == null && currentSubtitle.value.isNotEmpty) {
            currentSubtitle('');
          }
        }
      }
      if (podPlayerController.value.videoPlayerValue?.isCompleted ?? false) {
        isVideoCompleted(true);
        isBuffering(false);
        isLoading(false);
        if (isTrailer.value) {
          onVideoChange?.call();
          return;
        }
        storeViewCompleted();
        podPlayerController.value.pause();
      }
    } else if (youtubePlayerController.value.value.hasPlayed) {
      final duration = youtubePlayerController.value.value.metaData.duration;
      final remaining = duration - position;
      final threshold = duration.inSeconds * 0.20;
      playNextVideo(remaining.inSeconds <= threshold);
      if (!isTrailer.value) {
        final subtitle = availableSubtitleList
            .firstWhereOrNull((s) => s.start <= position && s.end >= position);
        if (subtitle != null && subtitle.data != currentSubtitle.value) {
          currentSubtitle(subtitle.data);
        } else if (subtitle == null && currentSubtitle.value.isNotEmpty) {
          currentSubtitle('');
        }
      }
      if (youtubePlayerController.value.value.playerState ==
          PlayerState.ended) {
        isVideoCompleted(true);
        isBuffering(false);
        isLoading(false);
        if (isTrailer.value) {
          onVideoChange?.call();
          return;
        }
        storeViewCompleted();
      }
    } else if (isWebViewActive()) {
      // WebView video ended check
      final position = currentVideoPosition.value;
      final duration = currentVideoTotalDuration.value;

      if (duration > Duration.zero) {
        final remaining = duration - position;
        final threshold = duration.inSeconds * 0.20;
        playNextVideo(remaining.inSeconds <= threshold);

        if (!isTrailer.value) {
          final subtitle = availableSubtitleList.firstWhereOrNull(
              (s) => s.start <= position && s.end >= position);
          if (subtitle != null && subtitle.data != currentSubtitle.value) {
            currentSubtitle(subtitle.data);
          } else if (subtitle == null && currentSubtitle.value.isNotEmpty) {
            currentSubtitle('');
          }
        }

        // Check if video is completed (within last 1 second for accuracy)
        if (remaining.inSeconds <= 1) {
          isVideoCompleted(true);
          isBuffering(false);
          isLoading(false);
          if (isTrailer.value) {
            onVideoChange?.call();
            return;
          }
          storeViewCompleted();
        }
      }
    }
    if (playNextVideo.value) {
      if (!isSkipFocusPermission) return;
      skipNextVideoFocusNode.requestFocus();
    }
  }

  bool get isSkipFocusPermission {
    if (Get.isRegistered<ContentDetailsController>()) {
      final contentDetailsController = Get.find<ContentDetailsController>();
      return !contentDetailsController.isSubscriptionDialogOpen.value;
    }
    return true;
  }

  Future<void> _checkAndPlayAdsAtPosition(Duration position) async {
    // Never show ads when the current playback is a trailer or already purchased content.
    if (isTrailer.value) {
      return;
    }

    if (isAdPlaying.value ||
        isResumingFromAd.value ||
        isInitializingPlayer.value) {
      return;
    }

    final int currentSecond = position.inSeconds;
    final totalDuration = getVideoTotalDuration();

    if (totalDuration.inSeconds <= 0) {
      return;
    }

    if (currentSecond < 5) {
      return;
    }

    /// --- Check Overlay Ads ONLY when no video ads are playing ---
    if (!isAdPlaying.value) {
      _checkOverlayAds(currentSecond);
    }

    /// --- Mid-roll Ad Trigger ---
    int? nearbyMidRollAd;
    for (final adSecond in midRollAdSeconds) {
      if ((currentSecond - adSecond).abs() <= 1 &&
          !shownMidRollAds.contains(adSecond)) {
        nearbyMidRollAd = adSecond;
        break;
      }
    }

    if (nearbyMidRollAd != null && midRollAds.isNotEmpty) {
      shownMidRollAds.add(nearbyMidRollAd);
      final adToPlay = midRollAds[currentAdIndex.value % midRollAds.length];
      currentAdIndex.value++;
      await playAd(adToPlay);
      return;
    }

    /// --- Post-roll Ad Trigger (at 90% completion, 70% for episodes) ---
    if (totalDuration.inSeconds > 30 && !isPostRollAdShown.value) {
      final isEpisode = _isEpisodeContent();
      final postRollPercentage = isEpisode ? 0.7 : 0.9;
      final postRollPosition =
          (totalDuration.inSeconds * postRollPercentage).round();

      if (currentSecond >= postRollPosition && postRollPosition > 30) {
        if (postRollAds.isNotEmpty) {
          log('+-+-+-+-+-+-+-+-+-Triggering post-roll ad at ${formatSecondsToHMS(currentSecond)}');
          isPostRollAdShown.value = true;
          await playAd(postRollAds.first);
          return;
        }
      }
    }
  }

  void _checkOverlayAds(int currentSecond) {
    // Extra safety checks - only show overlays during main content
    if (overlayAds.isEmpty ||
        isAdPlaying.value ||
        isResumingFromAd.value ||
        isInitializingPlayer.value ||
        isBuffering.value) {
      return;
    }

    // Find any overlay ads that should be triggered now
    final readyAds = overlayAds
        .where((ad) =>
            currentSecond >= ad.startTime &&
            !shownOverlayAds.contains(ad.startTime))
        .toList();

    if (readyAds.isNotEmpty) {
      // Show the first ready ad
      final overlayAd = readyAds.first;

      log('+-+-+-+-+-+-+-+-+-Triggering overlay ad during MAIN CONTENT at: ${formatSecondsToHMS(currentSecond)} (scheduled for: ${formatSecondsToHMS(overlayAd.startTime)}) - ${overlayAd.imageUrl}');
      shownOverlayAds.add(overlayAd.startTime);
      currentOverlayAd.value = overlayAd;

      // Auto-hide after duration
      overlayAdTimer?.cancel();
      overlayAdTimer = Timer(Duration(seconds: overlayAd.duration), () {
        if (currentOverlayAd.value == overlayAd) {
          log('+-+-+-+-+-+-+-+-+-Hiding overlay ad after ${overlayAd.duration} seconds');
          currentOverlayAd.value = null;
        }
      });
    }
  }

  void listenVideoEvent() {
    /// --- PodPlayer Listener ---
    if (podPlayerController.value.isInitialised) {
      podPlayerController.value.addListener(() {
        final position = podPlayerController.value.currentVideoPosition;
        final duration = podPlayerController.value.totalVideoLength;
        if (!showSkipIntroOverlay.value) showSkipIntroButton();

        if (duration > Duration.zero &&
            midRollAds.isNotEmpty &&
            midRollAdSeconds.isEmpty) {
          calculateMidRollTimes(duration);
        }
        _checkAndPlayAdsAtPosition(position);

        isVideoPlaying(
            podPlayerController.value.videoPlayerValue?.isPlaying ?? false);
        isLoading(!podPlayerController.value.isVideoPlaying);
        currentVideoPosition(position);
        currentVideoTotalDuration(duration);
        checkIfVideoEnded();
        if (isVideoPlaying.value) {
          updateCurrentSubtitle(position);
        }

        _monitorX265Performance(position, duration);
      });
    }

    /// --- YouTube Player Listener ---
    if (youtubePlayerController.value.value.isReady) {
      youtubePlayerController.value.addListener(() {
        final position = youtubePlayerController.value.value.position;
        final duration = youtubePlayerController.value.value.metaData.duration;
        if (!showSkipIntroOverlay.value) showSkipIntroButton();

        if (duration > Duration.zero &&
            midRollAds.isNotEmpty &&
            midRollAdSeconds.isEmpty) {
          calculateMidRollTimes(duration);
        }
        _checkAndPlayAdsAtPosition(position);

        isVideoPlaying(youtubePlayerController.value.value.isPlaying);
        isLoading(!youtubePlayerController.value.value.hasPlayed);
        currentVideoPosition(position);
        currentVideoTotalDuration(duration);
        checkIfVideoEnded();
        if (youtubePlayerController.value.value.isPlaying) {
          updateCurrentSubtitle(position);
        }
      });
    }

    /// --- WebView Listener ---
    if (isWebViewActive()) {
      // The ad check for WebView is handled inside its onMessageReceived callback
    }
  }

  void handleError(String? errorDescription) {
    log("Video Player Error: $errorDescription");
    errorMessage.value = errorDescription ?? 'An unknown error occurred';
  }

  Duration getVideoTotalDuration() {
    if (youtubePlayerController.value.value.isPlaying) {
      return youtubePlayerController.value.value.metaData.duration;
    } else if (podPlayerController.value.isVideoPlaying) {
      return podPlayerController.value.totalVideoLength;
    } else if (isWebViewActive()) {
      return currentVideoTotalDuration.value;
    } else {
      return Duration.zero;
    }
  }

  Duration getVideoCurrentPosition() {
    if (youtubePlayerController.value.value.isPlaying) {
      return youtubePlayerController.value.value.position;
    } else if (podPlayerController.value.isVideoPlaying) {
      return podPlayerController.value.currentVideoPosition;
    } else if (isWebViewActive()) {
      return currentVideoPosition.value;
    }
    return Duration.zero;
  }

  //region Video Controls

  void togglePlayPause() {
    if (isWebViewActive()) {
      // WebView play/pause control
      final playCommand = isVideoPlaying.value ? 'pause()' : 'play()';
      webViewController.value
          .runJavaScript('document.querySelector("video").$playCommand;');
    }
    if (youtubePlayerController.value.value.isReady) {
      try {
        youtubePlayerController.value.value.isPlaying
            ? youtubePlayerController.value.pause()
            : youtubePlayerController.value.play();
      } catch (e) {
        log('+-+-+-+-+-+-+-+-+-Error during YouTube toggle play/pause: $e');
      }
    }
    if (podPlayerController.value.isInitialised) {
      try {
        podPlayerController.value.isVideoPlaying
            ? podPlayerController.value.pause()
            : podPlayerController.value.play();
      } catch (e) {
        log('+-+-+-+-+-+-+-+-+-Error during PodPlayer toggle play/pause: $e');
      }
    }
  }

  void seekForward({Duration? duration}) {
    if (youtubePlayerController.value.value.isPlaying) {
      try {
        youtubePlayerController.value.seekTo(
          duration ??
              Duration(
                seconds: (youtubePlayerController
                            .value.value.metaData.duration.inSeconds >
                        (youtubePlayerController
                                .value.value.position.inSeconds +
                            appConfigs.value.forwardSeekSeconds))
                    ? youtubePlayerController.value.value.position.inSeconds +
                        appConfigs.value.forwardSeekSeconds
                    : youtubePlayerController
                        .value.value.metaData.duration.inSeconds,
              ),
        );
      } catch (e) {
        log('+-+-+-+-+-+-+-+-+-Error during YouTube seek forward: $e');
      }
    }
    if (podPlayerController.value.isVideoPlaying) {
      try {
        podPlayerController.value.videoSeekForward(
          duration ??
              Duration(
                seconds: (podPlayerController
                            .value.videoPlayerValue!.duration.inSeconds >
                        (podPlayerController
                                .value.videoPlayerValue!.position.inSeconds +
                            appConfigs.value.forwardSeekSeconds))
                    ? podPlayerController
                            .value.videoPlayerValue!.position.inSeconds +
                        appConfigs.value.forwardSeekSeconds
                    : podPlayerController
                        .value.videoPlayerValue!.duration.inSeconds,
              ),
        );
      } catch (e) {
        log('+-+-+-+-+-+-+-+-+-Error during PodPlayer seek forward: $e');
      }
    }
    if (isWebViewActive()) {
      // WebView seek forward
      final seekSeconds = duration?.inSeconds ?? 5;
      webViewController.value.runJavaScript(
          'const video = document.querySelector("video"); '
          'if (video) { '
          '  const newTime = Math.min(video.currentTime + $seekSeconds, video.duration); '
          '  video.currentTime = newTime; '
          '}');
    }
  }

  void seekBackward({bool isMediaKit = false}) {
    if (youtubePlayerController.value.value.isPlaying) {
      try {
        youtubePlayerController.value.seekTo(
          Duration(
            seconds: youtubePlayerController.value.value.position.inSeconds >=
                    appConfigs.value.backwardSeekSeconds
                ? youtubePlayerController.value.value.position.inSeconds -
                    appConfigs.value.backwardSeekSeconds
                : youtubePlayerController.value.value.position.inSeconds,
          ),
        );
      } catch (e) {
        log('+-+-+-+-+-+-+-+-+-Error during YouTube seek backward: $e');
      }
    }
    if (podPlayerController.value.isVideoPlaying) {
      try {
        podPlayerController.value.videoSeekBackward(
          Duration(
            seconds: podPlayerController
                        .value.videoPlayerValue!.position.inSeconds >=
                    appConfigs.value.backwardSeekSeconds
                ? podPlayerController
                        .value.videoPlayerValue!.position.inSeconds -
                    appConfigs.value.backwardSeekSeconds
                : podPlayerController
                    .value.videoPlayerValue!.position.inSeconds,
          ),
        );
      } catch (e) {
        log('+-+-+-+-+-+-+-+-+-Error during PodPlayer seek backward: $e');
      }
    }
    if (isWebViewActive()) {
      // WebView seek backward
      webViewController.value
          .runJavaScript('const video = document.querySelector("video"); '
              'if (video) { '
              '  const newTime = Math.max(video.currentTime - 5, 0); '
              '  video.currentTime = newTime; '
              '}');
    }
  }

  void play() {
    if (youtubePlayerController.value.value.playerState == PlayerState.paused) {
      youtubePlayerController.value.play();
    } else if (podPlayerController.value.isInitialised) {
      podPlayerController.value.play();

      if (videoUrlType.value.toLowerCase() == PlayerTypes.hls.toLowerCase()) {
        Future.delayed(Duration(milliseconds: 300), () {
          if (!podPlayerController.value.isVideoPlaying) {
            podPlayerController.value.play();
          }
        });
      } else if (videoUrlType.value.toLowerCase() ==
          PlayerTypes.local.toLowerCase()) {
        // Special handling for Local videos
        Future.delayed(Duration(milliseconds: 500), () {
          if (!podPlayerController.value.isVideoPlaying) {
            log('+-+-+-+-+-+-+-+-+-Local video play retry in play() method');
            podPlayerController.value.play();
          }
        });
      }
    } else if (isWebViewActive()) {
      // WebView play
      webViewController.value
          .runJavaScript('document.querySelector("video").play();');
    }

    isVideoPlaying(true);
  }

  void pause() async {
    if (youtubePlayerController.value.value.isPlaying) {
      youtubePlayerController.value.pause();
    } else if (podPlayerController.value.isInitialised) {
      podPlayerController.value.pause();
    } else if (isWebViewActive()) {
      // WebView pause
      webViewController.value
          .runJavaScript('document.querySelector("video").pause();');
    }
    isVideoPlaying(false);
  }

  /// Force refresh HLS video player - useful when video doesn't display
  Future<void> forceRefreshHLSPlayer() async {
    if (videoUrlType.value.toLowerCase() == PlayerTypes.hls.toLowerCase()) {
      try {
        // Dispose current controller
        if (podPlayerController.value.isInitialised) {
          podPlayerController.value.dispose();
        }
        await Future.delayed(Duration(milliseconds: 500));

        uniqueKey = UniqueKey();
        update();

        await initializePodPlayer(videoUrl.value);
      } catch (e) {
        log('+-+-+-+-+-+-+-+-+-Error during HLS force refresh: $e');
      }
    }
  }

  /// Force UI refresh for HLS video display
  void forceHLSDisplayRefresh() {
    if (videoUrlType.value.toLowerCase() == PlayerTypes.hls.toLowerCase()) {
      uniqueKey = UniqueKey();
      update();

      Future.delayed(Duration(milliseconds: 100), () {
        if (podPlayerController.value.isInitialised) {
          podPlayerController.value.play();
        }
      });
    }
  }

  void showProgressBar() {
    isProgressBarVisible.value = true;
    _hideProgressBarTimer?.cancel();
    checkIfVideoEnded();

    // For trailers, focus the Skip button by default when video is playing
    // Wait for video to actually start playing before focusing
    if (isTrailer.value) {
      Future.delayed(Duration(milliseconds: 800), () {
        // Only focus if video is actually playing and not initializing
        if (isVideoPlaying.value &&
            !isInitializingPlayer.value &&
            !isBuffering.value &&
            skipNextVideoFocusNode.canRequestFocus &&
            !skipNextVideoFocusNode.hasFocus) {
          if (!isSkipFocusPermission) return;
          skipNextVideoFocusNode.requestFocus();
          isSkipNextFocused(true);
        }
      });
    }

    _hideProgressBarTimer = Timer(
        isTrailer.value
            ? const Duration(seconds: 5)
            : const Duration(seconds: 10), () {
      requestVideoFocus();
      isProgressBarVisible(false);
      toggleSkipNextFocus(false);
      toggleQualityFocus(false);
      toggleSubtitleFocus(false);
      focusedQualityIndex(-1);
      focusedSubtitleIndex(-1);
    });
    update();
  }

  //endregion

  void onPlayOriginalVideo() {
    LiveStream().on(mOnWatchVideo, (val) {
      log('+-+-+-+-+-+-+-+-+-onPlayOriginalVideo: Transitioning from trailer to main video');
      // Set isTrailer to false BEFORE calling changeVideo so pre-roll ads can play
      isTrailer(false);
      playNextVideo(false);

      // Reset skip intro state when transitioning from trailer to main content
      skipIntroHandled = false;
      showSkipIntroOverlay.value = false;
      isSkipIntroFocused.value = false;
      skipIntroFocusNode.unfocus();
      log('+-+-+-+-+-+-+-+-+-Skip intro state reset for main video');
      log('+-+-+-+-+-+-+-+-+-Intro times after reset: introStartsAt="${videoModel.value.introStartsAt}", introEndsAt="${videoModel.value.introEndsAt}"');

      // Ensure skip intro listener is set up after transition
      showSkipIntroButton();
      log('+-+-+-+-+-+-+-+-+-Skip intro button listener ensured after trailer transition');

      // Reset ad state to allow pre-roll ads to play after trailer
      isResumingFromAd(false);

      isAutoPlay(true);
      isStoreContinueWatch(true);
      if ((val as List)[0] != null) {
        changeVideo(
          quality: (val)[0],
          isQuality: (val)[1],
          type: (val)[2],
          newVideoData: (val)[4],
          watchedTime: (val)[5],
        );
      }
    });
  }

  void changeVideo({
    required String quality,
    required bool isQuality,
    required String type,
    ContentModel? newVideoData,
    String watchedTime = '',
  }) async {
    if (newVideoData != null) {
      final currentVideoId = videoModel.value.id;
      final newVideoId = newVideoData.id;
      if (currentVideoId > -1 && currentVideoId == newVideoId) {
        log("[SUBTITLE] Same video content (trailer skip) - preserving subtitle cache: video_id=$currentVideoId");
      } else {
        log("[SUBTITLE] Video changed - clearing subtitle cache: current_video_id=$currentVideoId, new_video_id=$newVideoId");
        // _clearSubtitleCache();
      }
    }

    isLoading(true);
    final currentPlaybackPosition = isQuality
        ? getVideoCurrentPosition()
        : watchedTime.isNotEmpty
            ? getWatchedTimeInDuration(watchedTime)
            : Duration.zero;
    removeVideoChannelListener();
    playNextVideo(false);
    isVideoPlaying(false);
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      VideoData? selectedLink = isQuality
          ? videoQualities.firstWhereOrNull((link) =>
              link.quality.toLowerCase() == quality.toLowerCase() ||
              (quality.toLowerCase() ==
                      QualityConstants.defaultQuality.toLowerCase() &&
                  (link.quality.isEmpty ||
                      link.quality.toLowerCase() ==
                          QualityConstants.defaultQuality.toLowerCase())))
          : VideoData(
              url: quality,
              urlType: type,
              quality: QualityConstants.defaultQuality.toLowerCase());

      // If no link found for quality selection, try to find default quality
      if (isQuality && selectedLink == null) {
        if (quality.toLowerCase() ==
            QualityConstants.defaultQuality.toLowerCase()) {
          selectedLink = videoModel.value.defaultQuality;
          if (selectedLink.url.isEmpty && videoQualities.isNotEmpty) {
            // Fallback to first available quality if default not found
            selectedLink = videoQualities
                    .firstWhereOrNull((link) => link.url.isNotEmpty) ??
                videoQualities.first;
          }
        } else {
          // Try to find by exact match (case insensitive)
          selectedLink = videoQualities.firstWhereOrNull(
              (link) => link.quality.toLowerCase() == quality.toLowerCase());
        }
      }

      if (selectedLink == null || selectedLink.url.isEmpty) {
        log("Error: No valid video link found for quality: $quality");
        handleError("No valid video link found for selected quality");
        isLoading(false);
        return;
      }

      currentQuality(selectedLink.quality.isNotEmpty
          ? selectedLink.quality
          : QualityConstants.defaultQuality.toLowerCase());

      if (newVideoData != null) {
        videoModel = newVideoData.obs;

        if (newVideoData.videoQualities.isNotEmpty) {
          availableQualities(newVideoData.videoQualities
              .map((link) =>
                  link.quality.replaceAll(RegExp(r'[pPkK]'), '').toInt())
              .toList());
          videoQualities.clear();
          videoQualities(newVideoData.videoQualities);

          // Check if default_quality already exists in the list before inserting
          final hasDefaultQuality = videoQualities.any((link) =>
              link.quality.isEmpty ||
              link.quality.toLowerCase() ==
                  QualityConstants.defaultQuality.toLowerCase());

          if (!hasDefaultQuality) {
            videoQualities.insert(
                0,
                VideoData(
                    id: -1,
                    url: selectedLink.url,
                    urlType: selectedLink.urlType,
                    quality: QualityConstants.defaultQuality.toLowerCase()));
          } else {
            // Move existing default_quality to index 0
            final defaultQualityEntry = videoQualities.firstWhere((link) =>
                link.quality.isEmpty ||
                link.quality.toLowerCase() ==
                    QualityConstants.defaultQuality.toLowerCase());
            if (videoQualities.indexOf(defaultQualityEntry) != 0) {
              videoQualities.remove(defaultQualityEntry);
              videoQualities.insert(0, defaultQualityEntry);
            }
          }
        }

        /// Handle subtitles
        subtitleList.clear();
        if (newVideoData.subtitleList.isNotEmpty) {
          subtitleList(newVideoData.subtitleList);
          subtitleList.insert(
              0,
              SubtitleModel(
                  id: -1, language: locale.value.off.capitalizeEachWord()));

          /// Load default subtitle if available
          if (subtitleList
              .any((element) => element.isDefaultLanguage.getBoolInt())) {
            selectedSubtitleModel(subtitleList.firstWhere(
                (element) => element.isDefaultLanguage.getBoolInt()));
            loadSubtitles(selectedSubtitleModel.value);
          } else {
            currentSubtitle('');
          }
        } else {
          subtitleList.insert(
              0,
              SubtitleModel(
                  id: -1, language: locale.value.off.capitalizeEachWord()));
        }
        // Reset skip intro state when changing video
        skipIntroHandled = false;
        showSkipIntroOverlay(false);
        isSkipIntroFocused.value = false;
        skipIntroFocusNode.unfocus();
        log('+-+-+-+-+-+-+-+-+-Skip intro state reset in changeVideo');
        await _setupDynamicAds();
      }

      videoUrlType(selectedLink.urlType);
      videoUrl(selectedLink.url);

      log('+++-+-+-+-+------ New URL - ${videoUrl.value}');
      log('+++-+-+-+-+------ Upload Type -- ${videoUrlType.value}');

      // Play pre-roll ads before changing video quality
      // Note: We play pre-roll ads even if resuming from continue watch, as they should play before the video starts
      if (!isResumingFromAd.value && preRollAds.isNotEmpty) {
        for (int i = 0; i < preRollAds.length; i++) {
          await playAd(preRollAds[i]);
        }
      }
      isPostRollAdShown.value = false;
      shownMidRollAds.clear();
      shownOverlayAds.clear();
      currentAdIndex.value = 0;
      midRollAdSeconds.clear();
      pause();
      if (videoUrlType.value.toLowerCase() ==
          PlayerTypes.youtube.toLowerCase()) {
        if (youtubePlayerController.value.value.isPlaying) {
          isProgressBarVisible.value = false;
          youtubePlayerController.value.dispose();
        }
        await initializeYoutubePlayer();
      } else if (videoUrlType.value.toLowerCase() ==
              PlayerTypes.embedded.toLowerCase() ||
          videoUrlType.value.toLowerCase() == PlayerTypes.vimeo.toLowerCase()) {
        String url = videoUrl.value;
        if (videoUrlType.value.toLowerCase() ==
            PlayerTypes.vimeo.toLowerCase()) {
          url = "https://vimeo.com/${url.split("/").last}";
        } else {
          url = movieEmbedCode(videoUrl.value);
        }
        initializeWebViewPlayer(url);
      } else if (videoUrlType.value.toLowerCase() ==
              PlayerTypes.hls.toLowerCase() ||
          videoUrlType.value.toLowerCase() == PlayerTypes.url.toLowerCase() ||
          videoUrlType.value.toLowerCase() == PlayerTypes.local.toLowerCase() ||
          videoUrlType.value.toLowerCase() == PlayerTypes.x265.toLowerCase()) {
        log('+-+-+-+-+-+-+-+-+-Changing to PodPlayer content: ${videoUrlType.value}');
        podPlayerController.value.pause();

        // Use unified platform mapping so x265 requests include headers (Referer/User-Agent).
        final newVideoSource =
            getVideoPlatform(type: type, videoURL: videoUrl.value);

        if (podPlayerController.value.isInitialised) {
          await podPlayerController.value
              .changeVideo(
            playVideoFrom: newVideoSource,
          )
              .then((_) {
            log('+-+-+-+-+-+-+-+-+-Video changed successfully for ${videoUrlType.value}');
            seekForward(duration: currentPlaybackPosition);
            updateCurrentSubtitle(currentPlaybackPosition);
            listenVideoEvent();
            Future.delayed(Duration(milliseconds: 300), () {
              play();
            });
          }).onError((error, stackTrace) {
            log("Error during changeVideoQuality: ${error.toString()}");
            handleError(error.toString());
            final errorText = error.toString().toLowerCase();
            if (videoUrlType.value.toLowerCase() ==
                PlayerTypes.local.toLowerCase()) {
              log('+-+-+-+-+-+-+-+-+-Local video change failed: ${error.toString()}');
              if (errorText.contains('file') ||
                  errorText.contains('path') ||
                  errorText.contains('not found')) {
                errorMessage.value =
                    'Local video file not found or inaccessible. Please check the file path.';
              } else {
                errorMessage.value =
                    'Failed to load local video file. Please try again.';
              }
            }
          }).whenComplete(() {
            isLoading(false);
          });
        } else {
          log('+-+-+-+-+-+-+-+-+-PodPlayer not initialized, reinitializing for ${videoUrlType.value}');
          initializePodPlayer(videoUrl.value);
        }
      }

      uniqueKey = UniqueKey();
      uniqueProgressBarKey = UniqueKey();
      update();
    } catch (e) {
      log("Exception during changeVideoQuality: ${e.toString()}");
      handleError(e.toString());
    }
  }

  void onUpdateQualities() {
    LiveStream().on(onAddVideoQuality, (val) {
      if (val is List<VideoData>) {
        if (val.isNotEmpty) {
          (val).map((e) => log(e.toQualityJson()));
          availableQualities(val
              .map((link) =>
                  link.quality.replaceAll(RegExp(r'[pPkK]'), '').toInt())
              .toList());
          videoQualities.clear();
          videoQualities(val);

          // Remove any duplicate default_quality entries first
          final defaultQualityEntries = videoQualities
              .where((link) =>
                  link.quality.isEmpty ||
                  link.quality.toLowerCase() ==
                      QualityConstants.defaultQuality.toLowerCase())
              .toList();

          // Keep only the first default_quality entry and remove others
          if (defaultQualityEntries.length > 1) {
            for (int i = 1; i < defaultQualityEntries.length; i++) {
              videoQualities.remove(defaultQualityEntries[i]);
            }
          }

          // Check if default_quality exists in the list
          final defaultQualityFromList = videoQualities.firstWhereOrNull(
              (link) =>
                  link.quality.isEmpty ||
                  link.quality.toLowerCase() ==
                      QualityConstants.defaultQuality.toLowerCase());

          if (defaultQualityFromList == null) {
            // If no default_quality found, insert a synthetic one at index 0
            // Use the first available quality's URL if videoUrl is empty
            final urlToUse = videoUrl.value.isNotEmpty
                ? videoUrl.value
                : (videoQualities
                        .firstWhereOrNull((link) => link.url.isNotEmpty)
                        ?.url ??
                    videoQualities.first.url);
            final typeToUse = videoUrlType.value.isNotEmpty
                ? videoUrlType.value
                : (videoQualities
                        .firstWhereOrNull((link) => link.url.isNotEmpty)
                        ?.urlType ??
                    videoQualities.first.urlType);

            videoQualities.insert(
                0,
                VideoData(
                    id: -1,
                    url: urlToUse,
                    urlType: typeToUse,
                    quality: QualityConstants.defaultQuality.toLowerCase()));
          } else {
            // Move default_quality to index 0 if it's not already there
            if (videoQualities.indexOf(defaultQualityFromList) != 0) {
              videoQualities.remove(defaultQualityFromList);
              videoQualities.insert(0, defaultQualityFromList);
            }
            // Set current quality to default_quality if it's available
            if (defaultQualityFromList.quality.isNotEmpty) {
              currentQuality(defaultQualityFromList.quality);
            } else {
              currentQuality(QualityConstants.defaultQuality.toLowerCase());
            }
          }
          log("Quality List: ${videoQualities.length}");

          // If initialization was deferred due to missing URL/type, bootstrap now
          // But for trailers, prefer trailerData over videoQualities
          if ((videoUrl.value.isEmpty || videoUrlType.value.isEmpty)) {
            log('+-+-+-+-+-+-+-+-+-onAddVideoQuality: URL/type is empty, checking for trailer data...');
            log('+-+-+-+-+-+-+-+-+-isTrailer: ${isTrailer.value}');
            log('+-+-+-+-+-+-+-+-+-trailerData.length: ${videoModel.value.trailerData.length}');

            // For trailers, check trailerData first
            if (isTrailer.value && videoModel.value.trailerData.isNotEmpty) {
              final trailer = videoModel.value.trailerData
                      .firstWhereOrNull((v) => v.url.isNotEmpty) ??
                  videoModel.value.trailerData.first;
              if (trailer.url.isNotEmpty) {
                log('+-+-+-+-+-+-+-+-+-Bootstrapping trailer player from trailerData: type=${trailer.urlType}, url=${trailer.url.substring(0, trailer.url.length > 100 ? 100 : trailer.url.length)}...');
                videoUrl(trailer.url);
                videoUrlType(trailer.urlType);
                // Retry initialization with trailer URL
                initializePlayer();
                return;
              } else {
                log('+-+-+-+-+-+-+-+-+-WARNING: Trailer data exists but URL is empty!');
              }
            }

            // For non-trailers or if trailerData is empty, prefer default_quality from videoQualities
            final defaultQuality = videoQualities.firstWhereOrNull((v) =>
                (v.quality.isEmpty ||
                    v.quality.toLowerCase() ==
                        QualityConstants.defaultQuality.toLowerCase()) &&
                v.url.isNotEmpty);
            final primary = defaultQuality ??
                videoQualities.firstWhereOrNull((v) => v.url.isNotEmpty) ??
                (videoQualities.isNotEmpty ? videoQualities.first : null);
            if (primary != null) {
              log('+-+-+-+-+-+-+-+-+-Bootstrapping player from videoQualities: type=${primary.urlType}, url=${primary.url.substring(0, primary.url.length > 100 ? 100 : primary.url.length)}...');
              videoUrl(primary.url);
              videoUrlType(primary.urlType);

              // For trailers, we should not use videoQualities - this is a fallback
              if (isTrailer.value) {
                log('+-+-+-+-+-+-+-+-+-WARNING: Using videoQualities for trailer (should use trailerData instead)');
              }

              if (videoUrlType.value.toLowerCase() ==
                  PlayerTypes.youtube.toLowerCase()) {
                initializeYoutubePlayer();
              } else if (videoUrlType.value.toLowerCase() ==
                      PlayerTypes.embedded.toLowerCase() ||
                  videoUrlType.value.toLowerCase() ==
                      PlayerTypes.vimeo.toLowerCase()) {
                String url = videoUrl.value;
                if (videoUrlType.value.toLowerCase() ==
                    PlayerTypes.vimeo.toLowerCase()) {
                  url = "https://vimeo.com/${url.split("/").last}";
                } else {
                  url = movieEmbedCode(videoUrl.value);
                }
                initializeWebViewPlayer(url);
              } else {
                initializePodPlayer(videoUrl.value);
              }
            } else {
              log('+-+-+-+-+-+-+-+-+-ERROR: No valid URL found in videoQualities either!');
            }
          }
        }
      }
    });
  }

  //region subtitle cache management

  /// Get cached subtitles from shared preload service
  List<Subtitle>? _getCachedSubtitles(String url) {
    final cached = _subtitlePreloadService.getCachedSubtitles(url);
    if (cached != null) {
      log("[SUBTITLE] Retrieved from cache: url=$url, entries=${cached.length}");
    } else {
      log("[SUBTITLE] Cache miss: url=$url");
    }
    return cached == null ? null : List<Subtitle>.from(cached).toList();
  }

  /// Cache subtitles in shared preload service
  void _cacheSubtitles(String url, List<Subtitle> subtitles) {
    log("[SUBTITLE] Storing in cache: url=$url, entries=${subtitles.length}");
    _subtitlePreloadService.cacheSubtitles(url, subtitles);
  }

  //endregion

  //region subtitle

  void onUpdateSubtitle() {
    LiveStream().on(REFRESH_SUBTITLE, (val) async {
      if (val is List<SubtitleModel>) {
        log("[SUBTITLE] REFRESH_SUBTITLE event received: subtitle_count=${val.length}");
        selectedSubtitleModel(SubtitleModel());
        currentSubtitle('');
        if (val.isNotEmpty) {
          (val).map((e) => log(e.toJson()));
          subtitleList.clear();
          subtitleList.assignAll(val);
          subtitleList.insert(
              0,
              SubtitleModel(
                  id: -1, language: locale.value.off.capitalizeEachWord()));

          if (subtitleList
              .any((element) => element.isDefaultLanguage.getBoolInt())) {
            final defaultSubtitle = subtitleList.firstWhere(
                (element) => element.isDefaultLanguage.getBoolInt());
            log("[SUBTITLE] Default subtitle found: language=${defaultSubtitle.language}, id=${defaultSubtitle.id}");
            selectedSubtitleModel(defaultSubtitle);
            await loadSubtitles(selectedSubtitleModel.value);
          } else {
            log("[SUBTITLE] No default subtitle found");
            currentSubtitle('');
          }

          /// Preload other subtitles in background for faster switching
          log("[SUBTITLE] Starting background preload for remaining subtitles");
          _preloadSubtitles();
        }
      }
    });
  }

  void _preloadSubtitles() {
    /// Preload subtitles for other languages in background to reduce switching delay
    /// Note: Subtitles are already preloaded by SubtitlePreloadService when Content Details API is called
    /// This method is kept for backwards compatibility but will use the service cache
    int preloadCount = 0;
    for (final subtitle in subtitleList) {
      if (subtitle.id != selectedSubtitleModel.value.id &&
          subtitle.id != -1 &&
          _getCachedSubtitles(subtitle.subtitleFile) == null) {
        preloadCount++;
        log("[SUBTITLE] Queueing subtitle for background preload: language=${subtitle.language}, id=${subtitle.id}");

        /// Use the preload service for background loading
        _subtitlePreloadService.preloadSubtitle(subtitle).catchError((error) {
          log("[SUBTITLE] Background subtitle preload failed: language=${subtitle.language}, error=$error");
        });
      }
    }
    if (preloadCount == 0) {
      log("[SUBTITLE] All subtitles already cached, no preload needed");
    } else {
      log("[SUBTITLE] Queued $preloadCount subtitles for background preload");
    }
  }

  bool isValidSubtitleFormat(String url) {
    return url.endsWith('.srt') || url.endsWith('.vtt');
  }

  Future<void> loadSubtitles(SubtitleModel subtitle) async {
    try {
      final rawUrl = subtitle.subtitleFile;
      log("[SUBTITLE] loadSubtitles called: language=${subtitle.language}, id=${subtitle.id}, url=$rawUrl");

      /// Check cache first for instant loading
      final cachedSubtitles = _getCachedSubtitles(rawUrl);
      if (cachedSubtitles != null && cachedSubtitles.isNotEmpty) {
        log("[SUBTITLE] Loading subtitles from cache (instant): language=${subtitle.language}, entries=${cachedSubtitles.length}");
        availableSubtitleList.clear();
        availableSubtitleList(cachedSubtitles);
        selectedSubtitleModel(subtitle);

        /// Immediately update current subtitle without delay
        if (youtubePlayerController.value.value.isPlaying) {
          updateCurrentSubtitle(youtubePlayerController.value.value.position);
        } else if (podPlayerController.value.isInitialised) {
          updateCurrentSubtitle(podPlayerController.value.currentVideoPosition);
        }
        log("[SUBTITLE] Subtitle loaded successfully from cache: language=${subtitle.language}");
        return;
      }

      log("[SUBTITLE] Cache miss, loading from network: language=${subtitle.language}, url=$rawUrl");

      /// If not in cache, load from network
      isLoading(true);
      final encodedUrl = Uri.encodeFull(rawUrl);
      final downloadStartTime = DateTime.now();

      if (rawUrl.validateURL() && isValidSubtitleFormat(rawUrl)) {
        final response = await http.get(Uri.parse(encodedUrl));
        final downloadDuration = DateTime.now().difference(downloadStartTime);

        if (response.statusCode == 200) {
          log("[SUBTITLE] Subtitle downloaded from network: language=${subtitle.language}, size=${response.bodyBytes.length} bytes, duration=${downloadDuration.inMilliseconds}ms");

          String content;

          try {
            content = utf8.decode(response.bodyBytes);
          } catch (e) {
            final filtered =
                response.bodyBytes.where((b) => b != 0x00).toList();

            try {
              content = utf8.decode(filtered);
            } catch (e2) {
              content = latin1.decode(filtered);
            }
          }

          log("[SUBTITLE] Starting subtitle parsing in isolate: language=${subtitle.language}, format=${getSubtitleFormat(rawUrl)}");
          final parseStartTime = DateTime.now();

          // Run subtitle parsing in a background isolate
          final subtitles = await compute(
            (Map<String, dynamic> params) async {
              final provider = StringSubtitle(
                data: params['content'] as String,
                type: params['type'] as SubtitleType,
              );
              final controller = SubtitleController(provider: provider);
              await controller.initial();
              return controller.subtitles;
            },
            {
              'content': content,
              'type': getSubtitleFormat(rawUrl),
            },
          );

          final parseDuration = DateTime.now().difference(parseStartTime);
          log("[SUBTITLE] Subtitle parsed successfully: language=${subtitle.language}, entries=${subtitles.length}, parse_duration=${parseDuration.inMilliseconds}ms");

          /// Cache the parsed subtitles using shared service
          _cacheSubtitles(rawUrl, subtitles);

          availableSubtitleList.clear();
          availableSubtitleList(subtitles);
          selectedSubtitleModel(subtitle);

          /// Update current subtitle immediately
          if (youtubePlayerController.value.value.isPlaying) {
            updateCurrentSubtitle(youtubePlayerController.value.value.position);
          } else if (podPlayerController.value.isInitialised) {
            updateCurrentSubtitle(
                podPlayerController.value.currentVideoPosition);
          }
          log("[SUBTITLE] Subtitle loaded successfully from network: language=${subtitle.language}, total_duration=${DateTime.now().difference(downloadStartTime).inMilliseconds}ms");
        } else {
          log("[SUBTITLE] Failed to download subtitle: language=${subtitle.language}, HTTP ${response.statusCode}");
          throw Exception(
              'Subtitle file not found: HTTP ${response.statusCode}');
        }
      } else {
        log("[SUBTITLE] Invalid subtitle URL or format: language=${subtitle.language}, url=$rawUrl");
        throw Exception('Invalid subtitle URL or unsupported format');
      }
    } catch (e) {
      log("[SUBTITLE] Error loading subtitles: language=${subtitle.language}, error=$e");
      availableSubtitleList.clear();
      selectedSubtitleModel(SubtitleModel());
      currentSubtitle('');
    } finally {
      isLoading(false);
    }
  }

  SubtitleType getSubtitleFormat(String url) {
    if (url.endsWith('.srt')) return SubtitleType.srt;
    if (url.endsWith('.vtt')) return SubtitleType.vtt;
    return SubtitleType.custom;
  }

  Future<void> updateCurrentSubtitle(Duration position) async {
    if (availableSubtitleList.isNotEmpty) {
      final subtitle = availableSubtitleList
          .firstWhereOrNull((s) => s.start <= position && s.end >= position);
      if (subtitle != null && subtitle.data != currentSubtitle.value) {
        if (isTrailer.value) return;
        currentSubtitle(subtitle.data);
      } else if (subtitle == null && currentSubtitle.value.isNotEmpty) {
        currentSubtitle('');
      }
    }
  }

  //endregion

  //region Helper methods for Focus

  void toggleSkipNextFocus(bool value) {
    if (!isSkipFocusPermission) return;
    isSkipNextFocused(value);
    if (value) {
      skipNextVideoFocusNode.requestFocus();
    } else {
      skipNextVideoFocusNode.unfocus();
    }
  }

  void toggleQualityOptions(bool value) {
    log("Toggle Quality Options: $value");
    log("Before setting - focusedQualityIndex: ${focusedQualityIndex.value}");
    showQualityOptions(value);
    if (value) {
      // When opening quality options, focus the currently selected quality
      int selectedIndex = videoQualities.indexWhere((quality) =>
          quality.quality.toLowerCase() == currentQuality.value.toLowerCase());

      if (selectedIndex == -1) {
        selectedIndex = 0; // Default to first item if not found
      }

      log("Setting quality focus to index $selectedIndex (current quality: ${currentQuality.value})");
      focusedQualityIndex(selectedIndex);
      log("After setting - focusedQualityIndex: ${focusedQualityIndex.value}");
    } else {
      resetQualityFocus();
    }
  }

  void toggleQualityFocus(bool value) {
    log("Toggle Quality Focus: $value");
    log("Before toggle - focusedQualityIndex: ${focusedQualityIndex.value}");
    isQualityFocused(value);
    toggleQualityOptions(value);
    if (value) {
      qualityTabFocusNode.requestFocus();
    } else {
      qualityTabFocusNode.unfocus();
    }
    log("After toggle - focusedQualityIndex: ${focusedQualityIndex.value}");
  }

  void toggleSubtitleFocus(bool value) {
    log("Toggle Subtitle Focus: $value");
    isSubtitleFocused(value);
    toggleSubtitleOptions(value);

    if (value) {
      subtitleTabFocusNode.requestFocus();
    } else {
      subtitleTabFocusNode.unfocus();
    }
  }

  void toggleSubtitleOptions(bool value) {
    log("Toggle Subtitle Options: $value");
    showSubtitleOptions(value);
    if (value) {
      // When opening subtitle options, focus the currently selected subtitle
      int selectedIndex = subtitleList.indexWhere(
          (subtitle) => subtitle.id == selectedSubtitleModel.value.id);

      if (selectedIndex == -1) {
        selectedIndex = 0; // Default to first item if not found
      }

      log("Setting subtitle focus to index $selectedIndex (current subtitle: ${selectedSubtitleModel.value.language})");
      focusedSubtitleIndex(selectedIndex);

      /// Force update to ensure UI reflects the focus change
      update();
    } else {
      resetSubtitleFocus();
    }
  }

  void updateFocusFlags(FocusNode focusedNode) {
    toggleSkipNextFocus(focusedNode == skipNextVideoFocusNode);
    toggleQualityFocus(focusedNode == qualityTabFocusNode);
    toggleSubtitleFocus(focusedNode == subtitleTabFocusNode);
    update();
  }

  void handleVideoControls(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    // --- Skip Intro Logic (with proper navigation handling) ---
    if (showSkipIntroOverlay.value) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        // If subtitle menu is open → close first
        if (showSubtitleOptions.value || isSubtitleFocused.value) {
          toggleSubtitleOptions(false);
          toggleSubtitleFocus(false);
          return;
        }

        // If not in subtitle/quality → move focus to Skip Intro
        if (!showSubtitleOptions.value &&
            !showQualityOptions.value &&
            !isQualityFocused.value &&
            !isSubtitleFocused.value) {
          isSkipIntroFocused.value = true;
          FocusScope.of(Get.context!).requestFocus(skipIntroFocusNode);
          return;
        }
      }

      if (isSkipIntroFocused.value &&
          event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        isSkipIntroFocused.value = false;
        skipIntroFocusNode.unfocus();

        // If subtitles exist, return focus there
        toggleSubtitleFocus(true);
        return;
      }

      if (isSkipIntroFocused.value &&
          (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.select)) {
        onSkipIntro();
        isSkipIntroFocused.value = false;
        skipIntroFocusNode.unfocus();
        return;
      }
    }

    // --- Regular Controls ---
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (isQualityFocused.value || isSubtitleFocused.value) {
        handleMainFocusNavigation(event);
      } else {
        seekForward();
      }
      return;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (isQualityFocused.value || isSubtitleFocused.value) {
        handleMainFocusNavigation(event);
      } else {
        seekBackward();
      }
      return;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.select) {
      if (isProgressBarVisible.value || skipNextVideoFocusNode.hasFocus) {
        handleEnterKeyPress(event);
      } else {
        togglePlayPause();
      }
      return;
    }

    // --- Handle Key Repeat Events (long press on keys) ---
    if (event is KeyRepeatEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        togglePlayPause();
        return;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        seekForward();
        return;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        seekBackward();
        return;
      }
    }

    // --- Handle Back Button ---
    if (event.logicalKey == LogicalKeyboardKey.goBack) {
      if ((showQualityOptions.value || showSubtitleOptions.value) &&
          isProgressBarVisible.value) {
        // Close open options
        toggleSubtitleOptions(false);
        toggleQualityOptions(false);
        toggleQualityFocus(false);
        toggleSubtitleFocus(false);
        focusedQualityIndex(-1);
        focusedSubtitleIndex(-1);
        isProgressBarVisible(false);
        return;
      } else {
        Get.back();
        return;
      }
    }

    // --- Quality & Subtitle Tabs Navigation ---
    if (showQualityOptions.value &&
        event.logicalKey == LogicalKeyboardKey.arrowRight) {
      toggleQualityOptions(false);
      toggleQualityFocus(false);
      toggleSubtitleFocus(true);
      return;
    }

    if (showSubtitleOptions.value &&
        event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      toggleSubtitleOptions(false);
      toggleSubtitleFocus(false);
      toggleQualityFocus(true);
      return;
    }

    // --- Navigate within Quality List ---
    if (showQualityOptions.value) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        log("Quality Arrow Up pressed - event type: ${event.runtimeType}");
        if (event is KeyRepeatEvent) {
          log("Quality Arrow Up - KeyRepeatEvent, ignoring");
          return;
        }
        navigateQualityList(-1);
        return;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        log("Quality Arrow Down pressed - event type: ${event.runtimeType}");
        if (event is KeyRepeatEvent) {
          log("Quality Arrow Down - KeyRepeatEvent, ignoring");
          return;
        }
        navigateQualityList(1);
        return;
      }
    }

    // --- Navigate within Subtitle List ---
    if (showSubtitleOptions.value) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        log("Subtitle Arrow Up pressed - event type: ${event.runtimeType}");
        if (event is KeyRepeatEvent) {
          log("Subtitle Arrow Up - KeyRepeatEvent, ignoring");
          return;
        }
        navigateSubtitleList(-1);
        return;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        log("Subtitle Arrow Down pressed - event type: ${event.runtimeType}");
        if (event is KeyRepeatEvent) {
          log("Subtitle Arrow Down - KeyRepeatEvent, ignoring");
          return;
        }
        navigateSubtitleList(1);
        return;
      }
    }

    // --- Fallback Focus Navigation ---
    if (!showQualityOptions.value && !showSubtitleOptions.value) {
      handleMainFocusNavigation(event);
    }
  }

  // Handle single press of Enter key
  void handleEnterKeyPress(KeyEvent event) {
    if (isTrailer.value || (playNextVideo.value && hasNextVideo.value)) {
      handleMainFocusNavigation(event);
      return;
    } else {
      if (isQualityFocused.value &&
          showQualityOptions.value &&
          focusedQualityIndex.value > -1) {
        // Quality item is focused, select it
        onQualitySelected(focusedQualityIndex.value);
        return;
      } else if (showSubtitleOptions.value && focusedSubtitleIndex.value > -1) {
        // Subtitle item is focused,    select it
        onSubtitleSelected(focusedSubtitleIndex.value);
        return;
      }
    }

    // Default enter behavior - trigger focused action
    handleMainFocusNavigation(event);
  }

  void handleMainFocusNavigation(KeyEvent event) {
    // Determine focus order based on current state
    List<FocusNode> focusOrder = [];
    bool trailer = isTrailer.value;
    bool nextEpisode = hasNextVideo.value && playNextVideo.value;

    if (trailer) {
      focusOrder = [skipNextVideoFocusNode];
    } else if (nextEpisode) {
      focusOrder = [
        qualityTabFocusNode,
        subtitleTabFocusNode,
        skipNextVideoFocusNode
      ];
    } else {
      focusOrder = [qualityTabFocusNode, subtitleTabFocusNode];
    }

    int currentIndex = focusOrder.indexWhere((node) => node.hasFocus);

    // ENTER key: Trigger tab focus actions
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.select) {
      if (currentIndex == -1) return;
      FocusNode focusedNode = focusOrder[currentIndex];

      if (focusedNode == skipNextVideoFocusNode) {
        isLoading(true);
        if (isTrailer.value) {
          onVideoChange?.call();
        } else if (hasNextVideo.value && playNextVideo.value) {
          onWatchNextVideo?.call();
        }
        isLoading(false);
      } else if (focusedNode == qualityTabFocusNode) {
        toggleQualityFocus(true);
      } else if (focusedNode == subtitleTabFocusNode) {
        toggleSubtitleFocus(true);
      }
      return;
    }

    // DOWN key: show progress bar and focus first tab
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      log('++++++ EVENT.LOGICALKEY: ${event.logicalKey.debugName}');
      if (!isProgressBarVisible.value) {
        showProgressBar();
      } else {
        if (trailer) {
          if (!isSkipFocusPermission) return;
          skipNextVideoFocusNode.requestFocus();
          updateFocusFlags(skipNextVideoFocusNode);
        } else {
          qualityTabFocusNode.requestFocus();
          updateFocusFlags(qualityTabFocusNode);
        }
      }
      return;
    }

    // LEFT key: move to previous tab
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (currentIndex == -1 || currentIndex == 0) return;
      focusOrder[currentIndex - 1].requestFocus();
      updateFocusFlags(focusOrder[currentIndex - 1]);
      return;
    }

    // RIGHT key: move to next tab
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (currentIndex == -1 || currentIndex == focusOrder.length - 1) return;
      focusOrder[currentIndex + 1].requestFocus();
      updateFocusFlags(focusOrder[currentIndex + 1]);
      return;
    }
  }

  void navigateQualityList(int direction) {
    if (videoQualities.isEmpty) return;

    // Check if enough time has passed since last navigation
    final now = DateTime.now();
    if (_lastQualityNavigationTime != null &&
        now.difference(_lastQualityNavigationTime!) < _navigationDebounceTime) {
      log("Quality Navigation debounced - too soon since last navigation");
      return;
    }
    _lastQualityNavigationTime = now;

    int currentIndex = focusedQualityIndex.value;
    int newIndex;

    log("Quality Navigation: currentIndex=$currentIndex, direction=$direction, totalItems=${videoQualities.length}");

    if (currentIndex == -1) {
      // No item focused, focus first available item
      newIndex = 0;
    } else {
      newIndex = currentIndex + direction;

      // Handle wrapping or boundary behavior
      if (newIndex < 0) {
        // If going up from first item, stay on first item
        newIndex = 0;
      } else if (newIndex >= videoQualities.length) {
        // If going down from last item, stay on last item
        newIndex = videoQualities.length - 1;
      }
    }

    log("Quality Navigation: newIndex=$newIndex, currentIndex=$currentIndex");
    focusedQualityIndex(newIndex);
    update();
  }

  void resetQualityFocus() {
    log("Quality Focus Reset");
    focusedQualityIndex(-1);
    _lastQualityNavigationTime = null; // Reset debounce timer
  }

  // Add focus management for subtitle list

  void navigateSubtitleList(int direction) {
    if (subtitleList.isEmpty) return;

    // Check if enough time has passed since last navigation
    final now = DateTime.now();
    if (_lastSubtitleNavigationTime != null &&
        now.difference(_lastSubtitleNavigationTime!) <
            _navigationDebounceTime) {
      log("Subtitle Navigation debounced - too soon since last navigation");
      return;
    }
    _lastSubtitleNavigationTime = now;

    int currentIndex = focusedSubtitleIndex.value;
    int newIndex;

    log("Subtitle Navigation: currentIndex=$currentIndex, direction=$direction, totalItems=${subtitleList.length}");

    if (currentIndex == -1) {
      // No item focused, focus first available item
      newIndex = 0;
    } else {
      newIndex = currentIndex + direction;

      // Handle wrapping or boundary behavior
      if (newIndex < 0) {
        // If going up from first item, stay on first item
        newIndex = 0;
      } else if (newIndex >= subtitleList.length) {
        // If going down from last item, stay on last item
        newIndex = subtitleList.length - 1;
      }
    }

    log("Subtitle Navigation: newIndex=$newIndex, currentIndex=$currentIndex");
    focusedSubtitleIndex(newIndex);
    update();
  }

  void resetSubtitleFocus() {
    log("Subtitle Focus Reset");
    focusedSubtitleIndex(-1);
    _lastSubtitleNavigationTime = null; // Reset debounce timer
  }

  //endregion

  void onQualitySelected(int index) {
    if (currentQuality.value == videoQualities[index].quality) return;
    final selected = videoQualities[index];
    currentQuality(selected.quality);
    // Always call changeVideo to actually switch the video quality
    changeVideo(
        quality: selected.quality, isQuality: true, type: selected.urlType);
    requestVideoFocus();
    isProgressBarVisible(false);
    toggleSkipNextFocus(false);
    toggleQualityFocus(false);
    toggleSubtitleFocus(false);
  }

  void onSubtitleSelected(int index) {
    if (selectedSubtitleModel.value.id == subtitleList[index].id) {
      log("[SUBTITLE] Subtitle already selected, skipping: index=$index, language=${subtitleList[index].language}");
      return;
    }

    log("[SUBTITLE] User selected subtitle: index=$index, language=${subtitleList[index].language}, id=${subtitleList[index].id}");

    if (index == 0) {
      // "Off" option
      log("[SUBTITLE] Subtitle turned OFF");
      selectedSubtitleModel(SubtitleModel());
      currentSubtitle('');
      availableSubtitleList.clear();
    } else {
      final selected = subtitleList[index];

      /// Immediately update the selected subtitle model to provide instant feedback
      log("[SUBTITLE] Loading selected subtitle: language=${selected.language}, id=${selected.id}, url=${selected.subtitleFile}");
      selectedSubtitleModel(selected);

      /// Load subtitles asynchronously without blocking UI
      loadSubtitles(selected).catchError((error) {
        log("[SUBTITLE] Failed to load selected subtitle: language=${selected.language}, error=$error");
        // Revert selection on error
        selectedSubtitleModel(SubtitleModel());
        currentSubtitle('');
        availableSubtitleList.clear();
      });
    }

    /// Close subtitle options and reset focus
    toggleSubtitleOptions(false);
    resetSubtitleFocus();
    requestVideoFocus();
    isProgressBarVisible(false);
    toggleSkipNextFocus(false);
    toggleQualityFocus(false);
    toggleSubtitleFocus(false);
  }

  //region API calls

  Future<void> saveToContinueWatchVideo() async {
    if (videoModel.value.id != -1) {
      if (isBuffering.value || isResumingFromAd.value) {
        log("saveToContinueWatchVideo: Skipping - player is buffering or resuming from ad");
        return;
      }

      String watchedTime = '';
      String totalWatchedTime = '';
      if (videoModel.value.videoUploadType.toLowerCase() ==
          PlayerTypes.youtube) {
        if (youtubePlayerController.value.value.hasPlayed &&
            !isBuffering.value) {
          watchedTime =
              formatDuration(youtubePlayerController.value.value.position);
          totalWatchedTime =
              formatDuration(youtubePlayerController.value.metadata.duration);
        }
      } else {
        if (podPlayerController.value.videoPlayerValue != null &&
            podPlayerController.value.isVideoPlaying &&
            !isBuffering.value &&
            !isResumingFromAd.value) {
          watchedTime = formatDuration(
              podPlayerController.value.videoPlayerValue!.position);
          totalWatchedTime = formatDuration(
              podPlayerController.value.videoPlayerValue!.duration);
        }
      }

      if (watchedTime.isEmpty || totalWatchedTime.isEmpty) {
        log("No watched time to save - player not ready");
        return;
      }

      await CoreServiceApis.saveContinueWatch(
        request: {
          "entertainment_id": videoModel.value.watchedTime.isNotEmpty
              ? videoModel.value.entertainmentId
              : videoModel.value.id,
          "watched_time": watchedTime,

          ///store actual value of video player there is chance duration might be set different then actual duration of video
          "total_watched_time": totalWatchedTime,
          "entertainment_type": getTypeForContinueWatch(
              type: videoModel.value.type.toLowerCase()),
          if (profileId.value != 0) "profile_id": profileId.value,
          if (getTypeForContinueWatch(
                  type: videoModel.value.type.toLowerCase()) ==
              VideoType.tvshow)
            "episode_id": videoModel.value.episodeId > 0
                ? videoModel.value.episodeId
                : videoModel.value.id,
        },
      ).then((value) {
        HomeController homeScreenController = Get.find<HomeController>();
        homeScreenController.getDashboardDetail(showLoader: false);
        ProfileController profileController =
            Get.isRegistered<ProfileController>()
                ? Get.find<ProfileController>()
                : Get.put(ProfileController());

        profileController.getProfileDetail(showLoader: false);
      }).catchError((e) {
        log("Error ==> $e");
      });
    }
  }

  Future<void> storeViewCompleted() async {
    Map<String, dynamic> request = {
      "entertainment_id": videoModel.value.id,
      "user_id": loginUserData.value.id,
      "entertainment_type": getVideoType(type: videoModel.value.type),
      if (profileId.value != 0) "profile_id": profileId.value,
    };

    await CoreServiceApis.saveViewCompleted(request: request);
  }

  Future<void> startDate() async {
    await CoreServiceApis.startRentedContentDate(
      request: {
        "entertainment_id": videoModel.value.id,
        "entertainment_type": getVideoType(type: videoModel.value.type),
        "user_id": loginUserData.value.id,
        if (profileId.value != 0) "profile_id": profileId.value,
      },
    );
  }

  void onPlayPauseEmitRecived() {
    LiveStream().on(playerPlayPauseKey, (isPlay) {
      if (isPlay == true) play();
      if (isPlay == false) pause();
    });
  }

  void onChangePodVideo() {
    LiveStream().on(changeVideoInPodPlayer, (val) {
      playNextVideo(false);
      currentSubtitle('');
      selectedSubtitleModel(SubtitleModel());
      _handleVideoChange(val);
    });
  }

  void _handleVideoChange(dynamic val) {
    isAutoPlay(false);
    isTrailer(false);
    showSkipIntroOverlay(false);

    // Reset skip intro state when changing video
    skipIntroHandled = false;
    isSkipIntroFocused.value = false;
    skipIntroFocusNode.unfocus();
    log('+-+-+-+-+-+-+-+-+-Skip intro state reset in _handleVideoChange');

    if ((val as List)[0] != null) {
      changeVideo(
        quality: (val)[0],
        isQuality: (val)[1],
        type: (val)[2],
        newVideoData: (val)[4],
      );
    }
  }

  void disposeControllers() {
    try {
      youtubePlayerController.value.dispose();
      podPlayerController.value.dispose();
    } catch (e) {
      log("Error Disposing Controller: $e");
    }
  }

  //endregion

  @override
  Future<void> onClose() async {
    if (!isTrailer.value && videoModel.value.type != VideoType.liveTv) {
      await saveToContinueWatchVideo();
    }
    if (podPlayerController.value.isInitialised) {
      podPlayerController.value.removeListener(() => podPlayerController.value);
      podPlayerController.value.dispose();
    } else if (youtubePlayerController.value.value.hasPlayed) {
      youtubePlayerController.value.dispose();
    }

    // Reset skip intro listener flag
    _skipIntroListenerSet = false;

    LiveStream().dispose(playerPlayPauseKey);
    LiveStream().dispose(changeVideoInPodPlayer);
    LiveStream().dispose(podPlayerPauseKey);
    LiveStream().dispose(mOnWatchVideo);
    LiveStream().dispose(onAddVideoQuality);
    LiveStream().dispose(REFRESH_SUBTITLE);
    LiveStream().dispose(REFRESH_INTRO_DURATION);

    canChangeVideo(true);
    skipAdFocusNode.dispose();

    WakelockPlus.disable();
    removeVideoChannelListener();
    super.onClose();
  }
}

// Adapter: Provide backward-compatible getters expected by previous VideoPlayerModel usages
extension ContentModelAdapter on ContentModel {
  bool get isPurchased => details.hasContentAccess.getBoolInt();

  String get type => details.type;
  String get entertainmentType => details.entertainmentType;

  int get episodeId => details.type == VideoType.episode ? details.id : 0;

  String get introStartsAt => details.introStartsAt;
  String get introEndsAt => details.introEndsAt;

  String get trailerUrlType =>
      trailerData.isNotEmpty ? trailerData.first.urlType : '';
  String get trailerUrl => trailerData.isNotEmpty ? trailerData.first.url : '';

  // Choose the best available stream from qualities
  VideoData? get _primaryQuality {
    if (!isVideoQualitiesAvailable) return null;
    if (defaultQuality.url.isNotEmpty) return defaultQuality;
    final withUrl = videoQualities.firstWhereOrNull((v) => v.url.isNotEmpty);
    return withUrl ?? (videoQualities.isNotEmpty ? videoQualities.first : null);
  }

  String get videoUploadType => _primaryQuality?.urlType ?? '';
  String get videoUrlInput => _primaryQuality?.url ?? '';

  String get name => details.name;
  String get category => details.type;
  int get seasonId => details.tvShowData?.seasonId ?? -1;

  String get watchedTime => details.watchedDuration;
}
