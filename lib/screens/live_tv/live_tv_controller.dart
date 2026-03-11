import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:streamit_laravel/main.dart';
import 'package:streamit_laravel/screens/live_tv/model/live_tv_dashboard_response.dart';
import 'package:streamit_laravel/services/firebase_channel_service.dart';

class LiveTVController extends GetxController {
  RxBool isLoading = false.obs;
  RxBool isRefresh = false.obs;
  Rx<Future<LiveChannelDashboardResponse>> getLiveDashboardFuture =
      Future(() => LiveChannelDashboardResponse(data: LiveChannelModel())).obs;
  Rx<LiveChannelDashboardResponse> liveDashboard =
      LiveChannelDashboardResponse(data: LiveChannelModel()).obs;

  Rx<PageController> sliderCont = PageController(initialPage: 0).obs;
  Rx<ChannelModel> currentSliderPage = ChannelModel().obs;

  FocusNode sliderFocus = FocusNode();
  RxBool sliderHasFocus = false.obs;

  @override
  void onInit() {
    super.onInit();
    // استخدم الكاش إن وجد
    if (cachedLiveTvDashboard != null) {
      liveDashboard(cachedLiveTvDashboard);
    }
    getLiveDashboardDetail(startTimer: true);
  }

  /// جلب القنوات من Firebase Realtime Database
  Future<void> getLiveDashboardDetail(
      {bool showLoader = true, bool startTimer = false}) async {
    if (showLoader) {
      isLoading(true);
    }

    try {
      final response =
          await FirebaseChannelService.getLiveDashboardFromFirebase();
      liveDashboard(response);
      // احفظ في الكاش
      cachedLiveTvDashboard = response;
      getLiveDashboardFuture(Future.value(response));
    } catch (e) {
      log('getLiveDashboardDetail error: $e' as num);
      getLiveDashboardFuture(Future.error(e.toString()));
    } finally {
      isLoading(false);
    }
  }
}
