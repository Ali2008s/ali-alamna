import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/controllers/base_controller.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';

import '../../main.dart';
import '../../network/core_api.dart';
import '../../utils/common_base.dart';
import '../home/home_controller.dart';
import '../profile/profile_controller.dart';
import 'components/remove_from_watch_list_component.dart';

class WatchListController extends BaseListController<PosterDataModel> {
  RxBool isDelete = false.obs;
  RxList<PosterDataModel> selectedPosters = RxList();

  @override
  void onInit() {
    getListData();
    super.onInit();
  }

  @override
  Future<void> getListData({bool showLoader = true}) async {
    setLoading(showLoader);
    await listContentFuture(
      CoreServiceApis.getWatchList(
        page: currentPage.value,
        watchList: listContent,
        lastPageCallBack: (p0) {
          isLastPage(p0);
        },
      ),
    ).then((value) {
      log('value.length ==> ${value.length}');
    }).catchError((e) {
      log("getMovie List Err : $e");
    }).whenComplete(() => isLoading(false));
  }

  Future<void> handleRemoveFromWatchClick(BuildContext context) async {
    Get.bottomSheet(
      isDismissible: true,
      isScrollControlled: true,
      enableDrag: false,
      BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: RemoveFromWatchListComponent(
          onRemoveTap: () async {
            if (isLoading.value) return;
            hideKeyboard(context);
            isLoading(true);
            await CoreServiceApis.deleteFromWatchlist(idList: selectedPosters.validate().map((e) => e.id).toList()).then((value) {
              selectedPosters.validate().forEach(
                    (element) {
                  listContent.removeWhere((e) => e.id == element.id);
                },
              );
              isDelete.value = !isDelete.value;
              selectedPosters.clear();
              Get.back();

              successSnackBar(locale.value.removedFromWatchList);
              getListData();
              updateWatchList(selectedPosters.validate().map((e) => e.id).toList());
            }).catchError((e) {
              isLoading(false);
              errorSnackBar(error: e);
            }).whenComplete(() => isLoading(false));
          },
        ),
      ),
    );
  }

  Future<void> updateWatchList(List<int> idList) async {
    ProfileController profileCont = Get.find<ProfileController>();
    HomeController homeController = Get.find<HomeController>();
    profileCont.getProfileDetail();
    homeController.getDashboardDetail();
  }
}