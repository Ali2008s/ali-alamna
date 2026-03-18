import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/screens/home/components/slider_widget.dart';
import 'package:streamit_laravel/screens/home/components/mini_matches_widget.dart';
import 'package:streamit_laravel/screens/home/shimmer_home.dart';

import '../../components/app_scaffold.dart';
import '../../components/category_list/category_list_component.dart';
import '../../components/shimmer_widget.dart';
import '../../main.dart';
import '../../utils/constants.dart';
import '../../utils/empty_error_state_widget.dart';
import 'home_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController homeScreenController = Get.put(HomeController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      homeScreenController.requestInitialFocus();
    });
    
    return AppScaffoldNew(
      hasLeadingWidget: false,
      hideAppBar: true,
      isLoading: homeScreenController.isWatchListLoading,
      scaffoldBackgroundColor: black,
      body: Obx(
        () => SnapHelperWidget(
          future: homeScreenController.dashboardDetailsFuture.value,
          initialData: cachedDashboardDetailResponse,
          loadingWidget: const ShimmerHome(),
          errorBuilder: (error) {
            return SizedBox(
              width: Get.width,
              height: Get.height * 0.8,
              child: NoDataWidget(
                titleTextStyle: secondaryTextStyle(color: white),
                subTitleTextStyle: primaryTextStyle(color: white),
                title: error,
                retryText: locale.value.reload,
                imageWidget: const ErrorStateWidget(),
                onRetry: () async {
                  homeScreenController.init(forceSync: true, showLoader: true);
                },
              ).center(),
            );
          },
          onSuccess: (res) {
            return SingleChildScrollView(
              controller: homeScreenController.homeScrollController,
              padding: const EdgeInsets.only(bottom: 32),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Slider
                  Obx(() {
                    return SliderComponent(homeScreenCont: homeScreenController)
                        .visible(homeScreenController.sliderController.listContent.isNotEmpty);
                  }),

                  // ─── Mini Matches Widget (between sections) ───────────
                  const MiniMatchesWidget(),
                  const SizedBox(height: 8),

                  // Channel Category Sections
                  CategoryListComponent(
                    categoryList: homeScreenController.dashboardSectionList,
                    isPlayTrailer: true,
                  ),
                  Obx(
                    () => homeScreenController.showCategoryShimmer.value
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              4,
                              (index) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  16.height,
                                  const ShimmerWidget(
                                    height: Constants.shimmerTextSize,
                                    width: 180,
                                    radius: 6,
                                  ),
                                  16.height,
                                  HorizontalList(
                                    itemCount: 4,
                                    crossAxisAlignment: WrapCrossAlignment.start,
                                    wrapAlignment: WrapAlignment.start,
                                    spacing: 18,
                                    runSpacing: 18,
                                    padding: EdgeInsets.zero,
                                    itemBuilder: (context, index) {
                                      return ShimmerWidget(
                                        height: 150,
                                        width: Get.width / 4,
                                        radius: 6,
                                      );
                                    },
                                  )
                                ],
                              ).paddingSymmetric(vertical: 8, horizontal: 16),
                            ),
                          )
                        : const Offstage(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
