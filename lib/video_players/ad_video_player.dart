import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:pod_player/pod_player.dart';
import 'package:streamit_laravel/utils/empty_error_state_widget.dart';
import 'package:streamit_laravel/utils/extension/string_extension.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../components/loader_widget.dart';
import '../../utils/colors.dart';
import '../../utils/app_common.dart';
import 'package:streamit_laravel/utils/common_base.dart';

class ADVideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final double aspectRatio;
  final Function()? listener;

  const ADVideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.aspectRatio = 16 / 9,
    this.listener,
  });

  @override
  State<ADVideoPlayerWidget> createState() => ADVideoPlayerWidgetState();
}

class ADVideoPlayerWidgetState extends State<ADVideoPlayerWidget> {
  YoutubePlayerController? _youtubeController;
  PodPlayerController? _podController;

  bool get isYoutube => widget.videoUrl.contains('youtube.com') || widget.videoUrl.contains('youtu.be');

  Timer? _ticker;
  final _positionController = StreamController<Duration>.broadcast();
  final _playingController = StreamController<bool>.broadcast();

  Stream<Duration> get positionStream => _positionController.stream;

  Stream<bool> get playingStream => _playingController.stream;

  Duration get currentPosition {
    if (isYoutube) {
      return _youtubeController?.value.position ?? Duration.zero;
    } else {
      return _podController?.currentVideoPosition ?? Duration.zero;
    }
  }

  Duration get totalDuration {
    if (isYoutube) {
      return _youtubeController?.value.metaData.duration ?? Duration.zero;
    } else {
      return _podController?.totalVideoLength ?? Duration.zero;
    }
  }

  @override
  void initState() {
    super.initState();
    // Only initialize if videoUrl is not empty
    if (widget.videoUrl.isNotEmpty) {
      _initializePlayer();
    }
    _startTicker();
  }

  void _initializePlayer() {
    if (widget.videoUrl.isEmpty) {
      return;
    }

    if (isYoutube) {
      _youtubeController = YoutubePlayerController(
        initialVideoId: widget.videoUrl.getYouTubeId(),
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          enableCaption: false,
          hideControls: true,
        ),
      );
    } else {
      _podController?.dispose(); // Dispose existing controller if any

     
      final videoSource = getVideoPlatform(type: PlayerTypes.url, videoURL: widget.videoUrl);

      _podController = PodPlayerController(
        playVideoFrom: videoSource,
        podPlayerConfig: const PodPlayerConfig(
          autoPlay: true,
          isLooping: false,
          forcedVideoFocus: true,
        ),
      );
      _podController!.initialise().then((_) {
        if (mounted) {
          // Trigger rebuild to show the player instead of loader
          setState(() {});

          // Ensure video starts playing after initialization - try multiple times
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted && _podController != null && _podController!.isInitialised) {
              if (!_podController!.isVideoPlaying) {
                _podController!.play();

                // Retry if still not playing after a delay
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted && _podController != null && _podController!.isInitialised) {
                    if (!_podController!.isVideoPlaying) {
                      _podController!.play();
                      setState(() {}); // Force rebuild
                    } else {
                    }
                  }
                });
              }
            }
          });
        }
      }).catchError((error) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant ADVideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {

      // If URL was empty and now has a value, or if controller doesn't exist, initialize
      if (widget.videoUrl.isNotEmpty) {
        if (isYoutube) {
          if (_youtubeController == null) {
            _initializePlayer();
          } else {
            _youtubeController?.load(widget.videoUrl.getYouTubeId());
          }
        } else {
          // For PodPlayer, if controller doesn't exist or wasn't initialized properly, reinitialize
          if (_podController == null || !_podController!.isInitialised) {
            _initializePlayer();
          } else {
            // Use getVideoPlatform to get proper headers for ad videos
            final videoSource = getVideoPlatform(type: PlayerTypes.url, videoURL: widget.videoUrl);
            _podController
                ?.changeVideo(
              playVideoFrom: videoSource,
            )
                .then((_) {
              if (mounted) {
                setState(() {});
              }
              // Ensure video plays after change
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted && _podController != null && _podController!.isInitialised) {
                  if (!_podController!.isVideoPlaying) {
                    _podController!.play();
                  } 
                }
              });
            }).catchError((error) {
              // If changeVideo fails, try reinitializing
              _initializePlayer();
            });
          }
        }
      }
    }
  }

  //Stream listeners
  void addListeners() {
    if (widget.listener == null) return;
    if (isYoutube) {
      _youtubeController?.addListener(widget.listener!);
    } else {
      _podController?.addListener(widget.listener!);
    }
  }

  void removeListeners() {
    if (widget.listener == null) return;
    if (isYoutube) {
      _youtubeController?.removeListener(widget.listener!);
    } else {
      _podController?.removeListener(widget.listener!);
    }
  }

  void pause() {
    if (isYoutube) {
      _youtubeController?.pause();
    } else {
      _podController?.pause();
    }
  }

  void play() {
    if (isYoutube) {
      _youtubeController?.play();
    } else {
      if (_podController == null || !_podController!.isInitialised) {
        _initializePlayer();
      } else {
        _podController?.play();
        setState(() {}); // Trigger rebuild to ensure UI updates
        // Verify playback started with multiple retries
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _podController != null && _podController!.isInitialised) {
            if (!_podController!.isVideoPlaying) {
              _podController!.play();
              setState(() {});

              // Second retry
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted && _podController != null && _podController!.isInitialised) {
                  if (!_podController!.isVideoPlaying) {
                    _podController!.play();
                    setState(() {});
                  }
                }
              });
            }
          }
        });
      }
    }
  }

  void togglePlayPause() {
    if (isYoutube) {
      if (_youtubeController?.value.isPlaying == true) {
        _youtubeController?.pause();
      } else {
        _youtubeController?.play();
      }
    } else {
      if (_podController?.isVideoPlaying == true) {
        _podController?.pause();
      } else {
        _podController?.play();
      }
    }
  }

  //Ended
  bool get isEnded {
    if (isYoutube) {
      return _youtubeController?.value.playerState == PlayerState.ended;
    } else {
      return _podController?.videoPlayerValue?.isCompleted ?? false;
    }
  }

  bool get isPlaying {
    if (isYoutube) {
      return _youtubeController?.value.isPlaying ?? false;
    } else {
      return _podController?.isVideoPlaying ?? false;
    }
  }

  void mute() {
    if (isYoutube) {
      _youtubeController?.mute();
    } else {
      _podController?.mute();
    }
  }

  void unmute() {
    if (isYoutube) {
      _youtubeController?.unMute();
    } else {
      _podController?.unMute();
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) return;
      try {
        _positionController.add(currentPosition);
        _playingController.add(isPlaying);
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _positionController.close();
    _playingController.close();
    _youtubeController?.dispose();
    _podController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If URL is empty, show loading
    if (widget.videoUrl.isEmpty) {
      return ExcludeFocus(
        child: Container(
          width: Get.width,
          height: Get.width / widget.aspectRatio,
          color: Colors.black,
          child: LoaderWidget(
            loaderColor: appColorPrimary.withValues(alpha: 0.4),
          ),
        ),
      );
    }

    return ExcludeFocus(
      child: isYoutube
          ? (_youtubeController != null
              ? YoutubePlayer(
                  controller: _youtubeController!,
                  showVideoProgressIndicator: false,
                  progressIndicatorColor: appColorPrimary,
                  width: Get.width,
                  aspectRatio: widget.aspectRatio,
                  bottomActions: [],
                  topActions: [],
                )
              : Container(
                  width: Get.width,
                  height: Get.width / widget.aspectRatio,
                  color: Colors.black,
                  child: LoaderWidget(
                    loaderColor: appColorPrimary.withValues(alpha: 0.4),
                  ),
                ))
          : (_podController != null
              ? (_podController!.isInitialised
                  ? PodVideoPlayer(
                      controller: _podController!,
                      videoAspectRatio: widget.aspectRatio,
                      matchFrameAspectRatioToVideo: true,
                      matchVideoAspectRatioToFrame: true,
                      overlayBuilder: (options) => const Offstage(),
                      alwaysShowProgressBar: false,
                      hideFullScreenButton: true,
                      onLoading: (context) {
                        return LoaderWidget(
                          loaderColor: appColorPrimary.withValues(alpha: 0.4),
                        );
                      },
                      onVideoError: () {
                        return ErrorStateWidget();
                      },
                    )
                  : Container(
                      width: Get.width,
                      height: Get.width / widget.aspectRatio,
                      color: Colors.black,
                      child: LoaderWidget(
                        loaderColor: appColorPrimary.withValues(alpha: 0.4),
                      ),
                    ))
              : Container(
                  width: Get.width,
                  height: Get.width / widget.aspectRatio,
                  color: Colors.black,
                  child: LoaderWidget(
                    loaderColor: appColorPrimary.withValues(alpha: 0.4),
                  ),
                )),
    );
  }
}
