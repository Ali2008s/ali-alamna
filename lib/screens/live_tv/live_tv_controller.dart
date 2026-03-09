import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:streamit_laravel/main.dart';
import 'package:streamit_laravel/screens/live_tv/model/live_tv_dashboard_response.dart';

import '../../network/core_api.dart';

class LiveTVController extends GetxController {
  RxBool isLoading = false.obs;
  RxBool isRefresh = false.obs;
  Rx<Future<LiveChannelDashboardResponse>> getLiveDashboardFuture = Future(() => LiveChannelDashboardResponse(data: LiveChannelModel())).obs;
  Rx<LiveChannelDashboardResponse> liveDashboard = LiveChannelDashboardResponse(data: LiveChannelModel()).obs;

  Rx<PageController> sliderCont = PageController(initialPage: 0).obs;
  Rx<ChannelModel> currentSliderPage = ChannelModel().obs;

  FocusNode sliderFocus = FocusNode();
  RxBool sliderHasFocus = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (cachedLiveTvDashboard != null) {
      liveDashboard(cachedLiveTvDashboard);
    }
    getLiveDashboardDetail(startTimer: true);
  }

  ///Get Live Dashboard List
  Future<void> getLiveDashboardDetail({bool showLoader = true, bool startTimer = false}) async {
    if (showLoader) {
      isLoading(true);
    }
    await getLiveDashboardFuture(CoreServiceApis.getLiveDashboard()).then((value) {
      liveDashboard(value);
    }).whenComplete(() => isLoading(false));
  }
}