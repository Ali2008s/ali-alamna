import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/main.dart';
import 'package:streamit_laravel/video_players/video_player_controller.dart';

import '../utils/colors.dart';

class CommonProgressBar extends StatelessWidget {
  final Color backgroundColor;
  final Color progressColor;
  final Color bufferedColor;

  const CommonProgressBar({
    super.key,
    this.backgroundColor = const Color(0xFF444444),
    this.progressColor = Colors.blue,
    this.bufferedColor = Colors.white54,
    required this.controller,
  });

  final VideoPlayersController controller;

  bool get isLive => controller.liveShowModel.id > 0;

  RxDouble get currentProgress => (controller.currentVideoTotalDuration.value.inMilliseconds == 0
          ? 0
          : controller.currentVideoPosition.value.inMilliseconds /
              controller.currentVideoTotalDuration.value.inMilliseconds)
      .clamp(0.0, 1.0)
      .toDouble()
      .obs;

  RxString format(Duration d) => d.toString().split('.').first.padLeft(8, "0").obs;

  @override
  Widget build(BuildContext context) {
    commanProgressBarInit();
    return Obx(
      key: controller.uniqueProgressBarKey,
      () {
        if (controller.isProgressBarVisible.value && controller.isVideoPlaying.value) {
          return Column(
            spacing: 20,
            children: [
              Row(
                spacing: 16,
                children: [
                  // Start duration (00 se start hoga)
                  Obx(() => Text(
                        format(controller.currentVideoPosition.value).value,
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      )),

                  Expanded(
                    child: Obx(
                      () => LinearProgressIndicator(
                        value: currentProgress.value,
                        backgroundColor: backgroundColor,
                        valueColor: AlwaysStoppedAnimation<Color>(appColorPrimary),
                        minHeight: 2,
                      ),
                    ),
                  ),

                  // End duration (Total video duration)
                  Obx(() => Text(
                        format(controller.currentVideoTotalDuration.value).value,
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      )),
                ],
              ),
              if (!controller.isTrailer.value &&
                  controller.isProgressBarVisible.value &&
                  controller.isVideoPlaying.value &&
                  !isLive)
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  spacing: 32,
                  children: [
                    TextButton(
                      focusNode: controller.qualityTabFocusNode,
                      style: ButtonStyle(
                        padding: WidgetStatePropertyAll(EdgeInsets.zero),
                        visualDensity: VisualDensity.compact,
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadiusGeometry.circular(22),
                            side:
                                BorderSide(color: controller.isQualityFocused.value ? appColorPrimary : Colors.white54),
                          ),
                        ),
                      ),
                      onPressed: () {
                        controller.toggleQualityFocus(true);
                      },
                      child: Text(
                        locale.value.quality,
                        style: primaryTextStyle(color: controller.isQualityFocused.value ? appColorPrimary : white),
                      ),
                    ),
                    TextButton(
                      style: ButtonStyle(
                        padding: WidgetStatePropertyAll(EdgeInsets.zero),
                        visualDensity: VisualDensity.compact,
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadiusGeometry.circular(22),
                            side: BorderSide(
                                color: controller.isSubtitleFocused.value ? appColorPrimary : Colors.white54),
                          ),
                        ),
                      ),
                      onPressed: () {
                        controller.toggleSubtitleFocus(true);
                      },
                      focusNode: controller.subtitleTabFocusNode,
                      child: Text(
                        locale.value.subtitle,
                        style: primaryTextStyle(color: controller.isSubtitleFocused.value ? appColorPrimary : white),
                      ),
                    ),
                  ],
                )
            ],
          );
        } else {
          return Offstage();
        }
      },
    );
  }

  void commanProgressBarInit() {
    afterBuildCreated(() {
      if (controller.hasNextVideo.value) {
        final duration = controller.currentVideoTotalDuration.value;
        final remaining = duration - controller.currentVideoPosition.value;
        final threshold = duration.inSeconds * 0.20;
        controller.playNextVideo(remaining.inSeconds <= threshold);
      }
    });
  }
}
