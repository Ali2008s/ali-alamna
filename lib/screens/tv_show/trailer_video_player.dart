import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pod_player/pod_player.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';
import 'package:streamit_laravel/utils/extension/string_extension.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../components/cached_image_widget.dart';
import '../../../components/loader_widget.dart';
import '../../../utils/colors.dart';

class TrailerPlayerWidget extends StatefulWidget {
  final ContentModel videoModel;
  final double aspectRatio;
  final VoidCallback? onEnded;

  const TrailerPlayerWidget({
    super.key,
    required this.videoModel,
    this.aspectRatio = 16 / 9,
    this.onEnded,
  });

  @override
  State<TrailerPlayerWidget> createState() => TrailerPlayerWidgetState();
}

class TrailerPlayerWidgetState extends State<TrailerPlayerWidget> {
  YoutubePlayerController? _youtubeController;
  PodPlayerController? _podController;
  bool _isInitializing = true;
  bool _isPlaying = false;
  bool _isYoutubeReady = false;

  bool get isYoutube => widget.videoModel.trailerData.isNotEmpty &&
      (widget.videoModel.trailerData.first.url.contains('youtube.com') ||
          widget.videoModel.trailerData.first.url.contains('youtu.be'));

  bool get hasValidUrl =>
      widget.videoModel.trailerData.isNotEmpty &&
      widget.videoModel.trailerData.first.url.trim().isNotEmpty;

  bool get hasThumbnail =>
      widget.videoModel.details.thumbnailImage.trim().isNotEmpty &&
      widget.videoModel.details.thumbnailImage.trim().startsWith('https');

  bool get showLoader => !_isPlaying && (
    _isInitializing ||
    (isYoutube && (_youtubeController == null || !_isYoutubeReady)) ||
    (!isYoutube && (_podController == null || !(_podController?.isInitialised ?? false)))
  );

  void _onVideoPlaying() {
    if (mounted && !_isPlaying) {
      setState(() {
        _isPlaying = true;
        _isInitializing = false;
      });
    }
  }

  void _attachListeners() {
    if (isYoutube) {
      _youtubeController?.addListener(() {
        final value = _youtubeController?.value;
        if (value == null) return;
        if (value.isReady && !_isYoutubeReady && mounted) {
          setState(() => _isYoutubeReady = true);
        }
        if (value.isPlaying) _onVideoPlaying();
        if (value.playerState == PlayerState.ended) widget.onEnded?.call();
      });
    } else {
      _podController?.addListener(() {
        if (_podController?.isVideoPlaying == true) _onVideoPlaying();
        final current = _podController?.currentVideoPosition;
        final total = _podController?.totalVideoLength;
        if (current != null && total != null && (total - current).inMilliseconds <= 300) {
          widget.onEnded?.call();
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _createController();
    _attachListeners();
  }

  @override
  void didUpdateWidget(covariant TrailerPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoModel.trailerData == widget.videoModel.trailerData) return;
    if (!hasValidUrl) {
      _disposeControllers();
      return;
    }
    _resetState();
    final wasYoutube = oldWidget.videoModel.trailerData.isNotEmpty &&
        (oldWidget.videoModel.trailerData.first.url.contains('youtube.com') ||
            oldWidget.videoModel.trailerData.first.url.contains('youtu.be'));
    if (wasYoutube != isYoutube) {
      _disposeControllers();
      _createController();
      _attachListeners();
    } else if (isYoutube) {
      final videoId = widget.videoModel.trailerData.first.url.getYouTubeId();
      _youtubeController == null ? _createController() : _youtubeController?.load(videoId);
      _attachListeners();
    } else {
      final url = widget.videoModel.trailerData.first.url;
      if (_podController == null) {
        _createController();
      } else {
        _podController?.changeVideo(playVideoFrom: PlayVideoFrom.network(url));
      }
      _attachListeners();
    }
  }

  void _resetState() {
    if (mounted) {
      setState(() {
        _isInitializing = true;
        _isPlaying = false;
        _isYoutubeReady = false;
      });
    }
  }

  void _createController() {
    if (!hasValidUrl) return;
    _resetState();
    if (isYoutube) {
      final videoId = widget.videoModel.trailerData.first.url.getYouTubeId();
      if (videoId.isEmpty) return;
      if (kIsWeb) {
        _isInitializing = false;
        _isYoutubeReady = true;
        _isPlaying = false;
        return;
      }
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          enableCaption: false,
          hideControls: true,
          loop: true,
        ),
      );
    } else {
      final url = widget.videoModel.trailerData.first.url;
      if (url.isEmpty) return;
      _podController = PodPlayerController(
        playVideoFrom: PlayVideoFrom.network(url),
        podPlayerConfig: const PodPlayerConfig(autoPlay: true),
      );
      _podController!.initialise();
    }
  }

  void _disposeControllers() {
    _youtubeController?.dispose();
    _youtubeController = null;
    _podController?.dispose();
    _podController = null;
  }

  void pause() => isYoutube ? _youtubeController?.pause() : _podController?.pause();
  void play() => isYoutube ? _youtubeController?.play() : _podController?.play();

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  Widget _buildThumbnailBackground() {
    if (!hasThumbnail) {
      return Container(width: Get.width, height: Get.height, color: Colors.black);
    }
    return CachedImageWidget(
      url: widget.videoModel.details.thumbnailImage,
      fit: BoxFit.cover,
      width: Get.width,
      height: Get.height,
    );
  }

  Widget _buildVideoPlayer() {
    if (isYoutube) {
      if (_youtubeController == null) return const Offstage();
      if (kIsWeb) return _buildThumbnailBackground();
      return Opacity(
        opacity: _isPlaying ? 1.0 : 0.0,
        child: YoutubePlayer(
          controller: _youtubeController!,
          showVideoProgressIndicator: false,
          progressIndicatorColor: appColorPrimary,
          width: Get.width,
          aspectRatio: widget.aspectRatio,
          bottomActions: [],
          topActions: [],
          onReady: () {
            if (mounted) setState(() => _isYoutubeReady = true);
          },
        ),
      );
    } else {
      if (_podController == null) return const Offstage();
      return Opacity(
        opacity: _isPlaying ? 1.0 : 0.0,
        child: PodVideoPlayer(
          controller: _podController!,
          videoAspectRatio: widget.aspectRatio,
          matchFrameAspectRatioToVideo: true,
          matchVideoAspectRatioToFrame: true,
          overlayBuilder: (options) => const Offstage(),
          alwaysShowProgressBar: false,
          hideFullScreenButton: true,
          videoThumbnail: hasThumbnail
              ? DecorationImage(
                  image: NetworkImage(widget.videoModel.details.thumbnailImage),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.4),
                    BlendMode.darken,
                  ),
                )
              : null,
          onLoading: (context) => LoaderWidget(loaderColor: appColorPrimary.withValues(alpha: 0.4)),
          onVideoError: () => CachedImageWidget(
            url: widget.videoModel.details.thumbnailImage,
            fit: BoxFit.cover,
            width: Get.width,
            height: Get.height,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!hasValidUrl) {
      return SizedBox(
        width: Get.width,
        child: hasThumbnail
            ? DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(widget.videoModel.details.thumbnailImage),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.4), BlendMode.darken),
                  ),
                ),
                child: const SizedBox.shrink(),
              )
            : const Offstage(),
      );
    }

    return ExcludeFocus(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (showLoader) _buildThumbnailBackground(),
          _buildVideoPlayer(),
          if (showLoader)
            Center(child: LoaderWidget(loaderColor: appColorPrimary.withValues(alpha: 0.4))),
        ],
      ),
    );
  }
}
