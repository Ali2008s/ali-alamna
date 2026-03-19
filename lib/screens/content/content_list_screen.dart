// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/screens/content/components/content_list_shimmer.dart';
import 'package:streamit_laravel/screens/content/content_list_controller.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';
import 'package:streamit_laravel/screens/slider/banner_widget.dart';
import 'package:streamit_laravel/utils/colors.dart';
import 'package:streamit_laravel/utils/constants.dart';

import '../../components/app_scaffold.dart';
import '../../main.dart';
import '../../utils/animatedscroll_view_widget.dart';
import '../../utils/app_common.dart';
import '../../utils/empty_error_state_widget.dart';
import '../content/content_details_screen.dart';
import '../tv_show/tv_show_detail_screen.dart';

class ContentListScreen extends StatelessWidget {
  String? title = locale.value.movies;
  String? type;

  ContentListScreen({super.key, this.title, this.type});

  ContentListController? _contentListController;

  ContentListController get contentListController {
    final String controllerTag = 'content_list_controller_${type ?? VideoType.movie}';
    if (Get.isRegistered<ContentListController>(tag: controllerTag)) {
      _contentListController = Get.find<ContentListController>(tag: controllerTag);
    } else {
      _contentListController = Get.put(
        ContentListController(initialType: type),
        tag: controllerTag,
      );
    }
    return _contentListController!;
  }

  final RxBool hasFocus = false.obs;

  List<PosterDataModel>? _getInitialData() {
    switch (contentListController.contentType.value) {
      case VideoType.movie:
        return cachedContentList.isNotEmpty ? cachedContentList : null;
      case VideoType.video:
        return cachedVideoList.isNotEmpty ? cachedVideoList : null;
      case VideoType.tvshow:
        return cachedTvShowList.isNotEmpty ? cachedTvShowList : null;
      default:
        return cachedContentList.isNotEmpty ? cachedContentList : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize controller with proper settings
    final controller = contentListController;
    controller.screenTitle = title;

    return AppScaffoldNew(
      hasLeadingWidget: false,
      isLoading: contentListController.page.value == 1 ? false.obs : contentListController.isLoading,
      scaffoldBackgroundColor: appScreenBackgroundDark,
      topBarBgColor: transparentColor,
      hideAppBar: true,
      body: Obx(
        () => SnapHelperWidget(
          future: contentListController.getOriginalContentListFuture.value,
          initialData: _getInitialData(),
          loadingWidget: const NewShimmerMovieList(),
          errorBuilder: (error) {
            return NoDataWidget(
              titleTextStyle: secondaryTextStyle(color: white),
              subTitleTextStyle: primaryTextStyle(color: white),
              title: error,
              retryText: locale.value.reload,
              imageWidget: const ErrorStateWidget(),
              onRetry: () {
                contentListController.init();
              },
            );
          },
          onSuccess: (res) {
            return Obx(
              () => contentListController.originalContentList.isEmpty && contentListController.isLoading.isFalse
                  ? NoDataWidget(
                      titleTextStyle: boldTextStyle(color: white),
                      subTitleTextStyle: primaryTextStyle(color: white),
                      title: locale.value.noDataFound,
                      retryText: "",
                      imageWidget: const EmptyStateWidget(),
                    ).paddingSymmetric(horizontal: 16)
                  : AnimatedScrollView(
                      refreshIndicatorColor: appColorPrimary,
                      padding: EdgeInsets.only(bottom: 90),
                      children: [
                        if (contentListController.sliderController.bannerList.isNotEmpty) ...[
                          16.height,
                          BannerWidget(
                            sliderController: contentListController.sliderController,
                            onDownFromBanner: () {
                              if (contentListController.originalContentList.isNotEmpty) {
                                contentListController.originalContentList.first.itemFocusNode.requestFocus();
                              }
                            },
                          ),
                        ],
                        CustomAppScrollingWidget(
                          paddingLeft: Get.width * 0.01,
                          paddingRight: Get.width * 0.01,
                          paddingBottom: 0,
                          spacing: 8,
                          runSpacing: 8,
                          posterHeight: 150 * 1.2,
                          posterWidth: (Get.width / 8.8) * 1.2,
                          isLoading: false,
                          isLastPage: contentListController.isLastPage.value,
                          itemList: contentListController.originalContentList,
                          onNextPage: contentListController.onNextPage,
                          onSwipeRefresh: contentListController.onSwipeRefresh,
                          scrollController: contentListController.scrollController,
                          onUpFromItems: () {
                            contentListController.sliderController.sliderFocus.requestFocus();
                          },
                          onTap: (posterDet) {
                            if ((posterDet.details.access == MovieAccess.paidAccess &&
                                posterDet.details.requiredPlanLevel != 0 &&
                                currentSubscription.value.level < posterDet.details.requiredPlanLevel) || !posterDet.details.isDeviceSupported.getBoolInt()) {
                              showSubscriptionDialog(
                                  title: locale.value.subscriptionRequired,
                                  msg: locale.value.pleaseSubscribeOrUpgrade);
                            } else if ((posterDet.details.access == MovieAccess.payPerView ||
                                    posterDet.details.access == MovieAccess.payPerView) &&
                                !posterDet.details.hasContentAccess.getBoolInt()) {
                              showSubscriptionDialog(
                                  title: locale.value.rentRequired,
                                  msg: locale.value.rentToWatch,
                                  color: rentedColor);
                            } else {
                              // Route based on actual item type, not the list's declared type
                              if (posterDet.details.type == VideoType.tvshow ||
                                  posterDet.details.type == VideoType.episode) {
                                Get.to(() => TVShowPreviewScreen(), arguments: posterDet);
                              } else {
                                Get.to(() => ContentDetailsScreen(), arguments: posterDet);
                              }
                            }
                          },
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
