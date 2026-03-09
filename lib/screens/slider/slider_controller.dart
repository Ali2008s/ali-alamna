import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:streamit_laravel/controllers/base_controller.dart';
import 'package:streamit_laravel/main.dart';
import 'package:streamit_laravel/network/core_api.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';
import 'package:streamit_laravel/utils/app_common.dart';
import 'package:streamit_laravel/utils/common_base.dart';

class SliderController extends BaseListController<PosterDataModel> {
  RxString sliderType = "".obs;

  RxBool isWatchListLoading = false.obs;

  // Banner-specific properties
  Rx<PosterDataModel> currentSliderPage = PosterDataModel(details: ContentData()).obs;
  RxBool sliderHasFocus = false.obs;
  FocusNode sliderFocus = FocusNode();
  Rx<PageController> sliderPageController = PageController(initialPage: 0).obs;
  GlobalKey bannerGlobalKey = GlobalKey();

  // Alias for bannerList to maintain compatibility
  RxList<PosterDataModel> get bannerList => listContent;

  @override
  Future<void> getListData({bool showLoader = true}) async {
    isLoading(showLoader);

    await listContentFuture(CoreServiceApis.getSliderList(bannerFor: sliderType.value)).then((value) async {
      if (value.isNotEmpty) {
        /// Initialize currentSliderPage to the first banner when data loads
        currentSliderPage(value.first);
      }
      listContent(value);
    }).catchError((e) {
      isLoading(false);
      log("getBanner List Err : $e");
    }).whenComplete(() => isLoading(false));
  }

  Future<void> getBanner({bool showLoader = true, required String type}) async {
    sliderType(type);
    getListData();
  }

  Future<void> saveWatchLists(int index, {bool addToWatchList = true, required String type}) async {
    if (isWatchListLoading.isTrue) return;
    isWatchListLoading(true);

    if (addToWatchList) {
      await CoreServiceApis.saveWatchList(
        request: {
          "entertainment_id": listContent[index].id,
          if (profileId.value != 0) "profile_id": profileId.value,
        },
      ).then((value) async {
        await getBanner(type: type);
        successSnackBar(locale.value.addedToWatchList);
      }).catchError((e) {
        errorSnackBar(error: e);
      }).whenComplete(() {
        isWatchListLoading(false);
      });
    } else {
      await CoreServiceApis.deleteFromWatchlist(idList: [listContent[index].id]).then((value) async {
        await getBanner(type: type);
        successSnackBar(locale.value.removedFromWatchList);
      }).catchError((e) {
        errorSnackBar(error: e);
      }).whenComplete(() {
        isWatchListLoading(false);
      });
    }
  }
}
