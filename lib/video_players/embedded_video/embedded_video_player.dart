import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:streamit_laravel/video_players/video_player_controller.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewContentWidget extends StatefulWidget {
  final VideoPlayersController videoController;

  const WebViewContentWidget({
    super.key,
    required this.videoController,
  });

  @override
  State<WebViewContentWidget> createState() => _WebViewContentWidgetState();
}

class _WebViewContentWidgetState extends State<WebViewContentWidget> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GestureDetector(
      onTap: () {
        // Toggle progress bar visibility on tap
        if (widget.videoController.isProgressBarVisible.value) {
          widget.videoController.isProgressBarVisible(false);
        } else {
          widget.videoController.showProgressBar();
        }
      },
      onDoubleTap: () {
        // Toggle play/pause on double tap
        widget.videoController.togglePlayPause();
      },
      child: SizedBox(
        width: Get.width,
        height: Get.height,
        child: WebViewWidget(
          controller: widget.videoController.webViewController.value,
        ),
      ),
    );
  }
}
