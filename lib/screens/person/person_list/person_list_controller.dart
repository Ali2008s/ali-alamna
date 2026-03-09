import 'dart:async';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';

import '../../../network/core_api.dart';
import '../model/person_model.dart';

class PersonListController extends GetxController {
  RxBool isLoading = false.obs;
  RxBool isRefresh = false.obs;
  RxBool isLastPage = false.obs;
  RxInt page = 1.obs;

  Rx<Future<RxList<CastResponse>>> getOriginalPersonFuture = Future(() => RxList<CastResponse>()).obs;
  RxList<CastResponse> originalPersonList = RxList();

  @override
  void onInit() {
    getPersonDetails();
    super.onInit();
  }

  ///Get Person Details List
  Future<void> getPersonDetails({bool showLoader = true}) async {
    if (showLoader) {
      isLoading(true);
    }
    await getOriginalPersonFuture(
      CoreServiceApis.getActorsList(
        page: page.value,
        castType: "actor",
        getActorList: originalPersonList,
        lastPageCallBack: (p0) {
          isLastPage(p0);
        },
      ),
    ).then((value) {
      log('value.length ==> ${value.length}');
    }).catchError((e) {
      log("getPerson List List Err : $e");
    }).whenComplete(() => isLoading(false));
  }

  ///Refresh person list
  Future<void> refreshPersonList() async {
    page(1);
    isRefresh(true);
    await getPersonDetails(showLoader: false);
    isRefresh(false);
  }

  ///Load more persons for pagination
  Future<void> loadMorePersons() async {
    if (!isLastPage.value && !isLoading.value) {
      page(page.value + 1);
      await getPersonDetails(showLoader: false);
    }
  }

  ///Search persons by name
  List<CastResponse> searchPersons(String query) {
    if (query.isEmpty) return originalPersonList;
    return originalPersonList.where((castResponse) {
      if (castResponse.data.isNotEmpty) {
        Cast cast = castResponse.data.first;
        return cast.name.toLowerCase().contains(query.toLowerCase()) ||
               cast.designation.toLowerCase().contains(query.toLowerCase());
      }
      return false;
    }).toList();
  }

  ///Get person by ID
  CastResponse? getPersonById(int id) {
    try {
      return originalPersonList.firstWhere((castResponse) => 
        castResponse.data.isNotEmpty && castResponse.data.first.id == id);
    } catch (e) {
      return null;
    }
  }

  ///Clear all data
  void clearData() {
    originalPersonList.clear();
    page(1);
    isLastPage(false);
  }
}
