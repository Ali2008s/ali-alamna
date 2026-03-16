import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/components/shimmer_widget.dart';
import 'package:streamit_laravel/main.dart';
import 'package:streamit_laravel/screens/slider/slider_controller.dart';
import 'package:streamit_laravel/utils/app_common.dart';
import 'package:streamit_laravel/utils/colors.dart';
import 'package:streamit_laravel/utils/common_base.dart';

import '../../components/cached_image_widget.dart';
import '../../utils/constants.dart';
import '../content/content_details_screen.dart';
import '../content/model/content_model.dart';
import '../dashboard/dashboard_controller.dart';
import '../live_tv/live_tv_details/live_tv_details_screen.dart';
import '../tv_show/tv_show_detail_screen.dart';
import 'slider_banner_content.dart';
import 'slider_page_controller.dart';

class BannerWidget extends StatelessWidget {
  final SliderController sliderController;
  final VoidCallback? onDownFromBanner;

  const BannerWidget({super.key, required this.sliderController, this.onDownFromBanner});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        if (sliderController.bannerList.isEmpty && !sliderController.isLoading.value) {
          return Offstage();
        }
        return Focus(
          focusNode: sliderController.sliderFocus,
          canRequestFocus: true,
          skipTraversal: false,
          onFocusChange: (value) {
            sliderController.sliderHasFocus(value);

            if (value) {
              /// Ensure currentSliderPage is set when focus arrives
              if (sliderController.bannerList.isNotEmpty) {
                final currentPage = sliderController.sliderPageController.value.page?.round() ?? 0;
                if (currentPage < sliderController.bannerList.length) {
                  sliderController.currentSliderPage(sliderController.bannerList[currentPage]);
                }
              }

              if (sliderController.bannerGlobalKey.currentContext != null) {
                Future.delayed(Duration(milliseconds: 100), () {
                  Scrollable.ensureVisible(
                    sliderController.bannerGlobalKey.currentContext!,
                    alignment: 0.0,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                });
              }
            }
          },
          onKeyEvent: (node, event) {
            try {
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                  if (sliderController.sliderPageController.value.page != null &&
                      sliderController.sliderPageController.value.page! < 1.0) {
                    DashboardController dashCont = Get.find();
                    dashCont.bottomNavItems[dashCont.selectedBottomNavIndex.value].focusNode.requestFocus();
                  } else {
                    sliderController.sliderPageController.value
                        .previousPage(duration: Durations.medium3, curve: Curves.easeIn);
                  }
                  return KeyEventResult.handled;
                }
                if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                  sliderController.sliderPageController.value
                      .nextPage(duration: Durations.medium3, curve: Curves.easeIn);
                  return KeyEventResult.handled;
                }
                if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                  if (onDownFromBanner != null) {
                    onDownFromBanner!();
                  }
                  return KeyEventResult.handled;
                }
                if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
                  onSubscriptionLoginCheck(
                    title: sliderController.currentSliderPage.value.details.name,
                    planLevel: sliderController.currentSliderPage.value.details.requiredPlanLevel,
                    videoAccess: sliderController.currentSliderPage.value.details.access,
                    callBack: () {
                      handleWatchNowClick(sliderController.currentSliderPage.value);
                    },
                    planId: sliderController.currentSliderPage.value.details.id,
                  );
                  return KeyEventResult.handled;
                }
              }
            } catch (e) {
              log('error in slider key event: $e');
            }
            return KeyEventResult.ignored;
          },
          child: Column(
            key: sliderController.bannerGlobalKey,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  if (sliderController.isLoading.isTrue)
                    ShimmerWidget(
                      height: Get.height * 0.55,
                      width: Get.width,
                      radius: 6,
                    )
                  else
                    SizedBox(
                      height: Get.height * 0.55,
                      width: Get.width,
                      child: sliderController.bannerList.isNotEmpty
                          ? PageView(
                              controller: sliderController.sliderPageController.value,
                              onPageChanged: (value) {
                                sliderController.currentSliderPage(sliderController.bannerList[value]);
                                sliderController.sliderFocus.requestFocus();
                              },
                              children: List.generate(
                                sliderController.bannerList.length,
                                (index) {
                                  PosterDataModel data = sliderController.bannerList[index];

                                  return SliderPage(
                                    data: data,
                                    sliderController: sliderController,
                                    callback: () {
                                      onSubscriptionLoginCheck(
                                        title: data.details.name,
                                        planLevel: data.details.requiredPlanLevel,
                                        videoAccess: data.details.access,
                                        callBack: () {
                                          handleWatchNowClick(data);
                                        },
                                        planId: data.details.id,
                                      );
                                    },
                                  );
                                },
                              ),
                            )
                          : CachedImageWidget(url: '', height: Get.height * 0.6, width: Get.width),
                    ),
                ],
              ),
              if (sliderController.bannerList.length.validate() > 1 && sliderController.isLoading.isFalse)
                DotIndicator(
                  pageController: sliderController.sliderPageController.value,
                  pages: sliderController.bannerList,
                  indicatorColor: white,
                  unselectedIndicatorColor: darkGrayColor,
                  currentBoxShape: BoxShape.rectangle,
                  boxShape: BoxShape.rectangle,
                  borderRadius: radius(3),
                  currentBorderRadius: radius(3),
                  currentDotSize: 6,
                  currentDotWidth: 6,
                  dotSize: 6,
                ),
              20.height
            ],
          ),
        );
      },
    );
  }

  void handleWatchNowClick(PosterDataModel data) {
    final isFreeContent = data.details.access.toString() == MovieAccess.freeAccess;
    
    if (isFreeContent) {
        if (data.details.type == VideoType.tvshow) {
          Get.to(() => TVShowPreviewScreen(), arguments: data.details);
        } else if (data.details.type == VideoType.movie) {
          Get.to(() => ContentDetailsScreen(), arguments: data.details);
        } else if (data.details.type == VideoType.video) {
          Get.to(() => ContentDetailsScreen(), arguments: data.details);
        } else if (data.details.type == VideoType.liveTv) {
          Get.to(() => LiveShowDetailsScreen(), arguments: data.details);
        }
    } else {
      doIfLogin(onLoggedIn: () {
        if (data.details.access == MovieAccess.payPerView && !data.details.hasContentAccess.getBoolInt()) {
          showSubscriptionDialog(title: locale.value.rentRequired, msg: locale.value.rentToWatch, color: rentedColor);
        } else if ((data.details.access == MovieAccess.paidAccess && isMoviePaid(requiredPlanLevel: data.details.requiredPlanLevel)) || !data.details.isDeviceSupported.getBoolInt()) {
          log('isDeviceSupported: ${data.details.isDeviceSupported.getBoolInt()}');
          showSubscriptionDialog(title: locale.value.subscriptionRequired, msg: locale.value.pleaseSubscribeOrUpgrade);
        } else {
          if (data.details.type == VideoType.tvshow) {
            Get.to(() => TVShowPreviewScreen(), arguments: data.details);
          } else if (data.details.type == VideoType.movie) {
            Get.to(() => ContentDetailsScreen(), arguments: data.details);
          } else if (data.details.type == VideoType.video) {
            Get.to(() => ContentDetailsScreen(), arguments: data.details);
          } else if (data.details.type == VideoType.liveTv) {
            Get.to(() => LiveShowDetailsScreen(), arguments: data.details);
          }
        }
      });
    }
  }
}

class SliderPage extends StatelessWidget {
  const SliderPage({super.key, required this.data, required this.sliderController, required this.callback});

  final SliderController sliderController;
  final PosterDataModel data;
  final Function callback;

  @override
  Widget build(BuildContext context) {
    final SliderPageController controller = Get.put(
      SliderPageController(
        currentSliderPageRef: sliderController.currentSliderPage,
        sliderHasFocusRef: sliderController.sliderHasFocus,
        pageData: data,
        pageControllerRef: sliderController.sliderPageController,
        currentSliderPageValue: sliderController.currentSliderPage,
      ),
      tag: 'banner_${data.id}',
      permanent: false,
    );

    return Obx(() => SliderBannerContent(
          data: data,
          showTrailer: controller.showTrailer.value,
          hasFocus: sliderController.currentSliderPage.value.id == data.id && sliderController.sliderHasFocus.value,
          onTrailerEnded: controller.onTrailerEnded,
          onPosterTap: () {
            final isFreeContent = data.details.access.toString() == MovieAccess.freeAccess;
            if (isFreeContent) {
              if (data.details.type == VideoType.tvshow) {
                Get.to(() => TVShowPreviewScreen(), arguments: data.details);
              } else if (data.details.type == VideoType.movie) {
                Get.to(() => ContentDetailsScreen(), arguments: data.details);
              } else if (data.details.type == VideoType.video) {
                Get.to(() => ContentDetailsScreen(), arguments: data.details);
              } else if (data.details.type == VideoType.liveTv) {
                Get.to(() => LiveShowDetailsScreen(), arguments: data.details);
              }
            } else {
              doIfLogin(onLoggedIn: () {
                if ((data.details.access == MovieAccess.payPerView || data.details.access == MovieAccess.payPerView) &&
                    !data.details.hasContentAccess.getBoolInt()) {
                  showSubscriptionDialog(
                      title: locale.value.rentRequired, msg: locale.value.rentToWatch, color: rentedColor);
                } else if ((data.details.access == MovieAccess.paidAccess &&
                    currentSubscription.value.level < data.details.requiredPlanLevel) || !data.details.isDeviceSupported.getBoolInt()) {
                  showSubscriptionDialog(
                      title: locale.value.subscriptionRequired, msg: locale.value.pleaseSubscribeOrUpgrade);
                } else {
                  if (data.details.type == VideoType.tvshow) {
                    Get.to(() => TVShowPreviewScreen(), arguments: data.details);
                  } else if (data.details.type == VideoType.movie) {
                    Get.to(() => ContentDetailsScreen(), arguments: data.details);
                  } else if (data.details.type == VideoType.video) {
                    Get.to(() => ContentDetailsScreen(), arguments: data.details);
                  } else if (data.details.type == VideoType.liveTv) {
                    Get.to(() => LiveShowDetailsScreen(), arguments: data.details);
                  }
                }
              });
            }
          },
        ));
  }
}
