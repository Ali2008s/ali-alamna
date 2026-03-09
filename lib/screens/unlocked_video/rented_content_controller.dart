import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:streamit_laravel/main.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';
import 'package:streamit_laravel/utils/constants.dart';

import '../../network/core_api.dart';

class RentedContentController extends GetxController {
  RxBool isLoading = false.obs;
  RxBool isLastPage = false.obs;
  RxInt page = 1.obs;
  RxString languageName = "".obs;
  // filter can be: all, movie, video, episode, here
  RxString selectedFilter = 'all'.obs;

  Rx<Future<RxList<PosterDataModel>>> rentedContentFuture = Future(() => RxList<PosterDataModel>()).obs;
  RxList<PosterDataModel> rentedContentList = RxList();
  RxList<PosterDataModel> filteredRentedContentList = RxList();

  @override
  void onInit() {
    if (Get.arguments is String) {
      languageName(Get.arguments);
    }

    getRentedContentDetails();
    super.onInit();
  }

  FocusNode allFocusNode = FocusNode();
  FocusNode movieFocusNode = FocusNode();
  FocusNode videoFocusNode = FocusNode();
  FocusNode episodeFocusNode = FocusNode();

  void setFilter(String filter) {
    selectedFilter(filter);
    applyFilter();
  }

  void applyFilter() {
    final f = selectedFilter.value;
    filteredRentedContentList.clear();
    if (f == 'all') {
      filteredRentedContentList.addAll(rentedContentList);
    } else if (f == 'movie') {
      filteredRentedContentList.addAll(rentedContentList.where((e) => e.details.type == VideoType.movie));
    } else if (f == 'video') {
      filteredRentedContentList.addAll(rentedContentList.where((e) => e.details.type == VideoType.video));
    } else if (f == 'episodes') {
      filteredRentedContentList.addAll(rentedContentList.where((e) => e.details.type == VideoType.episode));
    }
  }

  Future<void> onNextPage() async {
    if (!isLastPage.value) {
      page++;
      await getRentedContentDetails();
    }
  }

  ///Get Rented content
  Future<void> getRentedContentDetails({bool showLoader = true}) async {
    isLoading(showLoader);

    await rentedContentFuture(
      CoreServiceApis.getRentedContent(
        page: page.value,
        rentedContentList: rentedContentList,
        lastPageCallBack: (p0) {
          isLastPage(p0);
        },
      ),
    )
        .then((value) {
          cachedRentedContentList = rentedContentList;
          applyFilter();
        })
        .catchError((e) {})
        .whenComplete(() => isLoading(false));
  }
}
