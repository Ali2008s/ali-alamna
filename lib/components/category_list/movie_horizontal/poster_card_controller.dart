import 'dart:async';

import 'package:get/get.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';

class PosterCardController extends GetxController {
  final PosterDataModel contentDetail;
  final VideoData? videoData;
  final bool isPlayTrailer;

  PosterCardController({required this.contentDetail, this.videoData, required this.isPlayTrailer});

  final RxBool hasFocus = false.obs;
  final RxBool showTrailer = false.obs;

  Timer? _autoplayTimer;
  Worker? _focusWorker;

  @override
  void onInit() {
    super.onInit();
    _focusWorker = ever(hasFocus, (_) => _onFocusChanged());
  }

  void setFocus(bool value) {
    hasFocus(value);
  }

  void _onFocusChanged() {
    final String trailerUrl = (contentDetail.details.trailerUrl ?? '').trim();
    final bool hasTrailer = trailerUrl.isNotEmpty || (videoData?.url.trim().isNotEmpty ?? false);
    if (hasFocus.value && hasTrailer && isPlayTrailer) {
      _scheduleAutoplay();
    } else {
      _cancelAutoplay(hide: true);
    }
  }

  void _scheduleAutoplay() {
    _autoplayTimer?.cancel();
    if (showTrailer.value) return;
    _autoplayTimer = Timer(const Duration(seconds: 2), () {
      if (hasFocus.value) {
        showTrailer(true);
      }
    });
  }

  void _cancelAutoplay({bool hide = false}) {
    _autoplayTimer?.cancel();
    _autoplayTimer = null;
    if (hide && showTrailer.value) {
      showTrailer(false);
    }
  }

  void onTrailerEnded() {
    showTrailer(false);
  }

  @override
  void onClose() {
    _cancelAutoplay();
    _focusWorker?.dispose();
    super.onClose();
  }
}


