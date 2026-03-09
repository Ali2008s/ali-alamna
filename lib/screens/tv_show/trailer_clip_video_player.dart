import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pod_player/pod_player.dart';
import 'package:streamit_laravel/components/loader_widget.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';
import 'package:streamit_laravel/utils/extension/string_extension.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../utils/colors.dart';

class TrailerClipPlayerWidget extends StatefulWidget {
  final VideoData videoModel;
  final double aspectRatio;
  final VoidCallback? onEnded;

  const TrailerClipPlayerWidget({
    super.key,
    required this.videoModel,
    this.aspectRatio = 16 / 9,
    this.onEnded,
  });

  @override
  State<TrailerClipPlayerWidget> createState() =>
      TrailerClipPlayerWidgetState();
}

class TrailerClipPlayerWidgetState extends State<TrailerClipPlayerWidget> {
  YoutubePlayerController? _youtubeController;
  PodPlayerController? _podController;
  bool _isInitializing = true;
  bool _isPlaying = false;
  bool _isYoutubeReady = false;

  bool get isYoutube =>
      widget.videoModel.url.isNotEmpty &&
      (widget.videoModel.url.contains('youtube.com') ||
          widget.videoModel.url.contains('youtu.be'));

  bool get hasValidUrl => widget.videoModel.url.trim().isNotEmpty;

  bool showControls = false;
  Timer? _hideTimer;
  bool isEnded = false; 

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _youtubeController?.dispose();
    _podController?.dispose();
    super.dispose();
  }

  void init() async {
    await _createControllerForCurrentModel();
    _attachListeners();
  }

  void _startAutoHideTimer() {
    setState(() => showControls = true);
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => showControls = false);
      }
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowLeft) {
      _rewind();
      _startAutoHideTimer();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowRight) {
      _forward();
      _startAutoHideTimer();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter) {
      _togglePlayPause();
      _startAutoHideTimer();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowDown) {
      _startAutoHideTimer();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _togglePlayPause() {
    if (isYoutube) {
      if (_youtubeController?.value.isPlaying ?? false) {
        _youtubeController?.pause();
      } else {
        _youtubeController?.play();
      }
    } else {
      if (_podController?.isVideoPlaying ?? false) {
        _podController?.pause();
      } else {
        _podController?.play();
      }
    }
  }

  void _rewind() {
    if (isYoutube) {
      final pos = _youtubeController?.value.position ?? Duration.zero;
      _youtubeController?.seekTo(pos - const Duration(seconds: 5));
    } else {
      final pos = _podController?.currentVideoPosition ?? Duration.zero;
      _podController?.videoSeekTo(pos - const Duration(seconds: 5));
    }
  }

  void _forward() {
    if (isYoutube) {
      final pos = _youtubeController?.value.position ?? Duration.zero;
      _youtubeController?.seekTo(pos + const Duration(seconds: 5));
    } else {
      final pos = _podController?.currentVideoPosition ?? Duration.zero;
      _podController?.videoSeekTo(pos + const Duration(seconds: 5));
    }
  }

  Widget _buildPlayer() {
    return isYoutube
        ? (_youtubeController == null
            ? const Offstage()
            : YoutubePlayer(
                controller: _youtubeController!,
                showVideoProgressIndicator: false,
                bottomActions: [],
                topActions: [],
                aspectRatio: widget.aspectRatio,
              ))
        : (_podController == null
            ? const Offstage()
            : PodVideoPlayer(
                controller: _podController!,
                videoAspectRatio: widget.aspectRatio,
                hideFullScreenButton: true,
                alwaysShowProgressBar: false,
                overlayBuilder: (options) => const Offstage(),
                onLoading: (context) => Center(
                  child: CircularProgressIndicator(
                    color: appColorPrimary,
                  ),
                ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    if (!hasValidUrl) {
      return Scaffold(
        body: SizedBox(
          width: Get.width,
          child: widget.videoModel.posterImage.trim().isNotEmpty &&
                  widget.videoModel.posterImage.trim().startsWith('https')
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(widget.videoModel.posterImage),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              : const Offstage(),
        ),
      );
    }

    return Scaffold(
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) => _handleKeyEvent(node, event),
        child: Stack(
          children: [
            Positioned.fill(child: _buildPlayer()),
            if (showControls)
              Positioned(
                bottom: 20,
                left: 8,
                right: 8,
                child: TrailerClipsProgressBar(isYoutube: isYoutube, podController: _podController, youtubeController: _youtubeController,),
              ),
            if (showLoader && isYoutube)
              Center(child: LoaderWidget(loaderColor: appColorPrimary.withValues(alpha: 0.4))),
          ],
        ),
      ),
    );
  }

  Future<void> _createControllerForCurrentModel() async {
    if (!hasValidUrl) return;

    if (isYoutube) {
      final String videoId = widget.videoModel.url.getYouTubeId();
      if (videoId.isEmpty) return;

      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          hideControls: true,
          enableCaption: false,
        ),
      );
    } else {
      final String url = widget.videoModel.url;

      _podController = PodPlayerController(
        playVideoFrom: PlayVideoFrom.network(url),
        podPlayerConfig: const PodPlayerConfig(autoPlay: true),
      );

      await _podController!.initialise();
    }
  }

  void _attachListeners() {
    if (isYoutube) {
      _youtubeController?.addListener(() {
        final val = _youtubeController!.value;
        if (val.isReady && !_isYoutubeReady && mounted) {
          setState(() => _isYoutubeReady = true);
        }
        if (val.isPlaying) _onVideoPlaying();
        if (val.playerState == PlayerState.ended) {
          if(isEnded) return;
          isEnded = true;
          widget.onEnded?.call();
        }
      });
    } else {
      _podController?.addListener(() {
        if (_podController?.isVideoPlaying == true) _onVideoPlaying();
        final p = _podController!.currentVideoPosition;
        final t = _podController!.totalVideoLength;

        if ((t - p).inSeconds < 1) {
          if(isEnded) return;
          isEnded = true;
          widget.onEnded?.call();
        }
      });
    }
  }

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
}


class TrailerClipsProgressBar extends StatefulWidget {
  final YoutubePlayerController? youtubeController;
  final PodPlayerController? podController;
  final bool isYoutube;
  const TrailerClipsProgressBar({super.key, required this.youtubeController, required this.podController, required this.isYoutube});

  @override
  State<TrailerClipsProgressBar> createState() => _TrailerClipsProgressBarState();
}

class _TrailerClipsProgressBarState extends State<TrailerClipsProgressBar> {
  
  @override
  void initState() {
    super.initState();
    _attachListeners();
  }

  void _attachListeners() {
    if (widget.isYoutube) {
      widget.youtubeController?.addListener(() {
        if(mounted) setState(() {});
      });
    } else {
      widget.podController?.addListener(() {
        if(mounted) setState(() {});
      });
    }
  }

  String format(Duration d) => d.toString().split('.').first.padLeft(8, "0");


  @override
  Widget build(BuildContext context) {
    Duration position = Duration.zero;
    Duration total = Duration.zero;

    if (widget.isYoutube) {
      position = widget.youtubeController!.value.position;
      total = widget.youtubeController!.value.metaData.duration;
    } else if (!widget.isYoutube) {
      position = widget.podController!.currentVideoPosition;
      total = widget.podController!.totalVideoLength;
    }

    final progress = total.inMilliseconds == 0
        ? 0.0
        : position.inMilliseconds / total.inMilliseconds;

    return Row(
      spacing: 16,
      children: [
        Text(
          format(position),
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: const Color(0xFF444444),
            valueColor: AlwaysStoppedAnimation<Color>(appColorPrimary),
            minHeight: 2,
          ),
        ),
        Text(
          format(total),
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }
}