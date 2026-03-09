import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:streamit_laravel/utils/colors.dart';

class ThumbnailComponent extends StatelessWidget {
  final String thumbnailImage;
  final int nextEpisodeNumber;
  final String nextEpisodeName;
  final bool isSkipNextFocused;

  const ThumbnailComponent({
    super.key,
    required this.thumbnailImage,
    required this.nextEpisodeName,
    required this.nextEpisodeNumber,
    this.isSkipNextFocused = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ThumbnailController>();

    return SizedBox(
      width: Get.width * 0.30,
      height: Get.width * 0.18,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: 320,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSkipNextFocused ? appColorPrimary : Colors.transparent,
                width: isSkipNextFocused ? 3 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  Image.network(
                    thumbnailImage,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Next Episode",
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                nextEpisodeName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                "Episode ${nextEpisodeNumber + 1}",
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Obx(() {
                          bool showPlay = controller.countdown.value <= 0;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              color: isSkipNextFocused ? appColorPrimary : Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSkipNextFocused ? Colors.white : Colors.transparent,
                                width: isSkipNextFocused ? 2 : 0,
                              ),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: SizedBox(
                              height: 24,
                              width: 24,
                              child: showPlay
                                  ? const Icon(
                                      Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    )
                                  : Center(
                                      child: Text(
                                        "${controller.countdown.value}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ThumbnailController extends GetxController {
  final RxInt countdown = 15.obs;
  final RxDouble progress = 1.0.obs;
  final RxBool isRunning = false.obs;
  final RxBool hasCompleted = false.obs;

  // track what parent last told us (visible or not)
  final RxBool parentVisible = false.obs;

  Timer? _timer;

  void start(VoidCallback onComplete) {
    if (isRunning.value) return;
    isRunning.value = true;
    hasCompleted.value = false;
    countdown.value = 15;
    progress.value = 1.0;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown.value > 0) {
        countdown.value -= 1;
        progress.value = countdown.value / 15;
      }

      if (countdown.value <= 0) {
        _timer?.cancel();
        _timer = null;
        isRunning.value = false;
        hasCompleted.value = true;
        onComplete();
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    isRunning.value = false;
  }

  /// Call this from parent whenever parent's visibility changes (called on every build).
  /// - visible == true  => parent says "thumbnail is visible now"
  /// - visible == false => parent says "thumbnail hidden"
  void onParentVisibilityChanged(bool visible, VoidCallback onComplete) {
    // Transition hidden -> visible: always reset completion and start
    if (visible && parentVisible.value == false) {
      // thumbnail re-appeared after being hidden: reset and start
      hasCompleted.value = false;
      start(onComplete);
    }
    // If stayed visible (parentVisible == true && visible == true)
    else if (visible && parentVisible.value == true) {
      // if it's not running and not completed, start (covers initial show)
      if (!isRunning.value && !hasCompleted.value) {
        start(onComplete);
      }
      // if hasCompleted == true => do nothing (shouldn't restart while still visible)
    }
    // If it becomes hidden: stop and reset hasCompleted so next show can start fresh.
    else if (!visible) {
      // stop current timer
      stop();
      // Important: reset completion on hide so next show starts again.
      hasCompleted.value = false;
    }

    // update last-known parent visibility
    parentVisible.value = visible;
  }

  @override
  void onClose() {
    stop();
    super.onClose();
  }
}