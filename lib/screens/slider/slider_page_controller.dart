import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/main.dart';
import 'package:streamit_laravel/screens/content/content_details_screen.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';
import 'package:streamit_laravel/screens/dashboard/dashboard_controller.dart';
import 'package:streamit_laravel/screens/live_tv/live_tv_details/live_tv_details_screen.dart';
import 'package:streamit_laravel/screens/tv_show/tv_show_detail_screen.dart';
import 'package:streamit_laravel/utils/app_common.dart';
import 'package:streamit_laravel/utils/colors.dart' as colors;
import 'package:streamit_laravel/utils/constants.dart';

class SliderPageController extends GetxController {
  final Rx<PosterDataModel> currentSliderPageRef;
  final RxBool sliderHasFocusRef;
  final PosterDataModel pageData;
  final Rx<PageController> pageControllerRef;
  final FocusNode? firstCategoryFocusNodeRef;
  final Rx<PosterDataModel> currentSliderPageValue;

  SliderPageController({
    required this.currentSliderPageRef,
    required this.sliderHasFocusRef,
    required this.pageData,
    required this.pageControllerRef,
    this.firstCategoryFocusNodeRef,
    required this.currentSliderPageValue,
  });

  final RxBool showTrailer = false.obs;

  Timer? _autoplayTimer;
  Timer? _previewStopTimer;
  Worker? _focusWorker;
  Worker? _pageWorker;

  bool _usingMainVideoPreview = false;

  @override
  void onInit() {
    super.onInit();
    _focusWorker = ever(sliderHasFocusRef, (_) => _onFocusOrPageChanged());
    _pageWorker = ever(currentSliderPageRef, (_) => _onFocusOrPageChanged());
    // schedule after first frame
    Future<void>.delayed(Duration.zero, _onFocusOrPageChanged);
  }

  void _onFocusOrPageChanged() {
    final bool isCurrentPage = currentSliderPageRef.value.id == pageData.id;
    final bool hasFocus = sliderHasFocusRef.value;
    final bool hasTrailerUrl = pageData.details.trailerUrl?.isNotEmpty == true;
    final bool shouldShowTrailer = isCurrentPage && hasFocus && hasTrailerUrl;

    if (!shouldShowTrailer) {
      // Cancel autoplay if not current page or no focus or no trailer
      _cancelAutoplay(hide: true);
      return;
    }

    // Start autoplay timer after 2 seconds
    _cancelAutoplay(hide: false);
    _autoplayTimer = Timer(const Duration(seconds: 2), () {
      // Double-check conditions before showing trailer
      if (currentSliderPageRef.value.id == pageData.id && sliderHasFocusRef.value && pageData.details.trailerUrl?.isNotEmpty == true) {
        showTrailer(true);
      }
    });
  }

  void _cancelAutoplay({bool hide = false}) {
    _autoplayTimer?.cancel();
    _autoplayTimer = null;
    _previewStopTimer?.cancel();
    _previewStopTimer = null;
    if (hide && showTrailer.value) {
      showTrailer(false);
    }
    // Restore original trailer URL if we swapped it for main video preview
    if (_usingMainVideoPreview) {
      _usingMainVideoPreview = false;
    }
  }

  void onTrailerEnded() {
    _previewStopTimer?.cancel();
    _previewStopTimer = null;
    // Restore original trailer URL if we swapped it
    if (_usingMainVideoPreview) {
      _usingMainVideoPreview = false;
    }
    showTrailer(false);
  }

  /// Handle keyboard navigation for slider
  KeyEventResult handleKeyEvent(KeyEvent event) {
    try {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          return handleArrowLeftKey();
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          return handleArrowRightKey();
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          return handleArrowDownKey();
        }
        if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
          return handleSelectKey();
        }
      }
    } catch (e) {
      log('error in handleKeyEvent: $e');
    }
    return KeyEventResult.ignored;
  }

  /// Handle arrow left key navigation
  KeyEventResult handleArrowLeftKey() {
    if (pageControllerRef.value.page != null && pageControllerRef.value.page! < 1.0) {
      final DashboardController dashCont = Get.find();
      dashCont.bottomNavItems[dashCont.selectedBottomNavIndex.value].focusNode.requestFocus();
    } else {
      pageControllerRef.value.previousPage(duration: Durations.medium3, curve: Curves.easeIn);
    }
    return KeyEventResult.handled;
  }

  /// Handle arrow right key navigation
  KeyEventResult handleArrowRightKey() {
    pageControllerRef.value.nextPage(duration: Durations.medium3, curve: Curves.easeIn);
    return KeyEventResult.handled;
  }

  /// Handle arrow down key navigation
  KeyEventResult handleArrowDownKey() {
    // Move focus to first item of the first visible category list
    if (firstCategoryFocusNodeRef != null) {
      firstCategoryFocusNodeRef!.requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Handle select/enter key navigation
  KeyEventResult handleSelectKey() {
    onSubscriptionLoginCheck(
      title: currentSliderPageValue.value.details.name,
      planLevel: currentSliderPageValue.value.details.requiredPlanLevel,
      videoAccess: currentSliderPageValue.value.details.access,
      callBack: () {
        handleWatchNowClick(currentSliderPageValue.value);
      },
      planId: currentSliderPageValue.value.details.id,
    );
    return KeyEventResult.handled;
  }

  /// Handle watch now click with subscription/login check
  void handleWatchNowClick(PosterDataModel data) {
    doIfLogin(onLoggedIn: () {
      if ((data.details.access == MovieAccess.payPerView) && !data.details.hasContentAccess.getBoolInt()) {
        showSubscriptionDialog(title: locale.value.rentRequired, msg: locale.value.rentToWatch, color: colors.rentedColor);
      } else if ((data.details.access == MovieAccess.paidAccess) && !data.details.hasContentAccess.getBoolInt()) {
        showSubscriptionDialog(title: locale.value.subscriptionRequired, msg: locale.value.pleaseSubscribeOrUpgrade);
      } else {
        navigateToContentDetails(data);
      }
    });
  }

  /// Navigate to appropriate screen based on content type
  void navigateToContentDetails(PosterDataModel data) {
    if (data.details.type == VideoType.tvshow) {
      Get.to(() => TVShowPreviewScreen(), arguments: data.details);
    } else if (data.details.type == VideoType.movie) {
      Get.to(() => ContentDetailsScreen(), arguments: data.details);
    } else if (data.details.type == VideoType.video) {
      Get.to(() => ContentDetailsScreen(), arguments: data.details);
    } else if (data.details.type == VideoType.liveTv) {
      Get.to(() => LiveShowDetailsScreen(), arguments: data.details);
    }
  }

  /// Handle poster tap with subscription check
  void handlePosterTap() {
    final data = pageData;
    if ((data.details.access == MovieAccess.payPerView) && !data.details.hasContentAccess.getBoolInt()) {
      showSubscriptionDialog(title: locale.value.rentRequired, msg: locale.value.rentToWatch, color: colors.rentedColor);
    } else if ((data.details.access == MovieAccess.paidAccess) && !data.details.hasContentAccess.getBoolInt()) {
      showSubscriptionDialog(title: locale.value.subscriptionRequired, msg: locale.value.pleaseSubscribeOrUpgrade);
    } else {
      navigateToContentDetails(data);
    }
  }

  @override
  void onClose() {
    _cancelAutoplay();
    _focusWorker?.dispose();
    _pageWorker?.dispose();
    super.onClose();
  }
}
