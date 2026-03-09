import 'dart:async';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';
import 'package:streamit_laravel/utils/constants.dart';

import '../../../network/core_api.dart';
import '../model/genres_model.dart';

class GenresDetailsController extends GetxController {
  RxBool isLoading = false.obs;
  RxBool isRefresh = false.obs;
  RxBool isLastPage = false.obs;
  RxInt page = 1.obs;
  RxInt genresId = 0.obs;
  Rx<Future<List<PosterDataModel>>> getGenresDetailsFuture = Future(() => <PosterDataModel>[]).obs;
  RxList<PosterDataModel> genresDetailsList = RxList();

  ScrollController scrollController = ScrollController();

  bool isUiLoaded = false;

  @override
  void onInit() {
    if (Get.arguments is GenreModel) {
      genresId((Get.arguments as GenreModel).id);
    }
    super.onInit();
    scrollController.addListener(
      () {
        if (scrollController.position.pixels == scrollController.position.maxScrollExtent && !isLoading.value) {
          onNextPage();
        }
      },
    );
    getGenresDetails();
  }

  Future<void> onNextPage() async {
    if (!isLastPage.value) {
      page(page.value + 1);
      getGenresDetails();
    }
  }

  ///Get Genres Wise Movie List
  Future<void> getGenresDetails({bool showLoader = true}) async {
    if (showLoader) {
      isLoading(true);
    }

    await getGenresDetailsFuture(
      CoreServiceApis.getContentList(
        page: page.value,
        type: VideoType.movie,
        contentList: genresDetailsList,
        params: "genres_id=${genresId.value}",
        lastPageCallBack: (p0) {
          isLastPage(p0);
        },
      ),
    ).then((value) {
      log('value.length ==> ${value.length}');
    }).catchError((e) {
      log("getGenres List Err : $e");
    }).whenComplete(() => isLoading(false));
  }
}
