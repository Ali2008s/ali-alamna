import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:streamit_laravel/main.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';
import 'package:streamit_laravel/screens/slider/slider_controller.dart';
import 'package:streamit_laravel/utils/constants.dart';

import '../../network/core_api.dart';

class ContentListController extends GetxController {
  ContentListController({String? initialType}) {
    if (initialType != null && initialType.isNotEmpty) {
      contentType(initialType);
    }
  }
  RxBool isLoading = false.obs;
  RxBool isLastPage = false.obs;
  RxInt page = 1.obs;
  RxString languageName = "".obs;
  RxString contentType = VideoType.movie.obs;
  String? screenTitle;

  Rx<Future<List<PosterDataModel>>> getOriginalContentListFuture = Future(() => <PosterDataModel>[]).obs;
  RxList<PosterDataModel> originalContentList = RxList();
  SliderController sliderController = SliderController();

  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    //  Get.put(GlobalVideoController());
    if (Get.arguments is String) {
      languageName(Get.arguments);
    }

    // Only set content type if it hasn't been set already (to prevent overriding)
    if (contentType.value.isEmpty) {
      log('ContentListController: on Init - setting initial content type');
      // Determine content type based on arguments or default to movie
      if (Get.arguments is Map && Get.arguments['type'] != null) {
        contentType(Get.arguments['type']);
      } else if (Get.arguments is String) {
        // Handle string arguments for backward compatibility
        contentType(Get.arguments);
      } else {
        // Determine content type from screen title if available
        if (screenTitle != null) {
          contentType(_getContentTypeFromTitle(screenTitle!));
        } else {
          // Default to movie if no arguments provided
          contentType(VideoType.movie);
        }
      }
    } else {
      log('ContentListController: onInit - content type already set to ${contentType.value}, not overriding');
    }

    // Set appropriate cached list based on content type
    switch (contentType.value) {
      case VideoType.movie:
        if (cachedContentList.isNotEmpty) {
          originalContentList = cachedContentList;
        }
        break;
      case VideoType.video:
        if (cachedVideoList.isNotEmpty) {
          originalContentList = cachedVideoList;
        }
        break;
      case VideoType.tvshow:
        if (cachedTvShowList.isNotEmpty) {
          originalContentList = cachedTvShowList;
        }
        break;
    }

    init();
    super.onInit();
  }

  Future<void> init() async {
    String bannerType = BannerType.movie;
    switch (contentType.value) {
      case VideoType.movie:
        bannerType = BannerType.movie;
        break;
      case VideoType.video:
        bannerType = BannerType.video;
        break;
      case VideoType.tvshow:
        bannerType = BannerType.tvShow;
        break;
    }

    await Future.wait(
      [
        sliderController.getBanner(type: bannerType),
        getContentList(),
      ],
    );
  }

  Future<void> onNextPage() async {
    if (!isLastPage.value) {
      page++;
      await getContentList();
    }
  }

  Future<void> onSwipeRefresh() async {
    page(1);
    await init();
  }

  ///Get Content List based on type
  Future<void> getContentList({bool showLoader = true, String language = ""}) async {
    if (isLoading.value) return;
    isLoading(showLoader);

    log('ContentListController: getContentList called with type: ${contentType.value}');
    await getOriginalContentListFuture(
      CoreServiceApis.getContentList(
        page: page.value,
        type: contentType.value,
        contentList: originalContentList,
        params: languageName.value.isNotEmpty ? "language=${languageName.value}" : "",
        lastPageCallBack: (p0) {
          isLastPage(p0);
        },
      ),
    ).then((value) {
      // Update appropriate cached list based on content type
      switch (contentType.value) {
        case VideoType.movie:
          cachedContentList = originalContentList;
          break;
        case VideoType.video:
          cachedVideoList = originalContentList;
          break;
        case VideoType.tvshow:
          cachedTvShowList = originalContentList;
          break;
      }
    }).whenComplete(() => isLoading(false));
  }

  String _getContentTypeFromTitle(String title) {
    if (title.toLowerCase().contains('video')) {
      return VideoType.video;
    } else if (title.toLowerCase().contains('tv') || title.toLowerCase().contains('show')) {
      return VideoType.tvshow;
    } else {
      return VideoType.movie;
    }
  }

  /// Method to update content type and reinitialize
  Future<void> updateContentType(String newType) async {
    log('ContentListController: updateContentType called with newType: $newType, currentType: ${contentType.value}');
    contentType(newType);
    // Clear current data
    originalContentList.clear();
    // Reset page to force fresh API call
    page(1);
    // Clear slider controller data to force fresh banner fetch
    sliderController = SliderController();
    // Force fresh API call by clearing the future and calling init
    getOriginalContentListFuture = Future(() => <PosterDataModel>[]).obs;
    await init();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
