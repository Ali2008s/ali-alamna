import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';
import 'package:streamit_laravel/utils/constants.dart';

import '../../main.dart';
import '../../network/core_api.dart';

class PersonController extends GetxController {
  RxBool isLoading = false.obs;
  RxBool isRefresh = false.obs;
  RxBool isLastPage = false.obs;
  RxInt page = 1.obs;
  RxInt actorId = 0.obs;
  ScrollController scrollController = ScrollController();
  ScrollController innerScrollController = ScrollController();

  Rx<Future<List<PosterDataModel>>> getOriginalMovieListFuture = Future(() => <PosterDataModel>[]).obs;
  RxList<PosterDataModel> originalMovieList = RxList();

  bool isUiLoaded = false;

  @override
  void onInit() {
    page(1);
    super.onInit();
    scrollController.addListener(
      () {
        if (scrollController.position.pixels == scrollController.position.maxScrollExtent && !isLoading.value) {
          onNextPage();
        }
      },
    );
    getPersonMovieDetails();
  }

  Future<void> onNextPage() async {
    if (!isLastPage.value) {
      page(page.value + 1);
      getPersonMovieDetails();
    }
  }

  Future<void> onSwipeRefresh() async {
    page(1);
    getPersonMovieDetails();
  }

  ///Get Person Wise Movie List
  Future<void> getPersonMovieDetails({bool showLoader = true}) async {
    if (showLoader) {
      isLoading(true);
    }
    await getOriginalMovieListFuture(
      CoreServiceApis.getContentList(
        page: page.value,
        type: VideoType.movie,
        contentList: originalMovieList,
        params: actorId.value > 0 ? "actor_id=${actorId.value}" : "",
        lastPageCallBack: (p0) {
          isLastPage(p0);
        },
      ),
    ).then((value) {
      cachedMovieList = originalMovieList;
      log('value.length ==> ${value.length}');
    }).catchError((e) {
      log("getPerson Movie List Err : $e");
    }).whenComplete(() => isLoading(false));
  }

  @override
  void onClose() {
    page(1);
    super.onClose();
  }
}
