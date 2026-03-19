import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart' hide DotIndicator;
import 'package:streamit_laravel/screens/content/content_details_screen.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';
import 'package:streamit_laravel/screens/dashboard/dashboard_controller.dart';
import 'package:streamit_laravel/screens/live_tv/live_tv_details/live_tv_details_screen.dart';
import 'package:streamit_laravel/screens/tv_show/tv_show_detail_screen.dart';
import 'package:streamit_laravel/utils/constants.dart';

import '../../../components/cached_image_widget.dart';
import '../../../components/dot_indicator.dart';
import '../../../utils/colors.dart';
import '../../../services/focus_sound_service.dart';
import '../../slider/slider_banner_content.dart';
import '../../slider/slider_page_controller.dart';
import '../home_controller.dart';

class SliderComponent extends StatelessWidget {
  const SliderComponent({super.key, required this.homeScreenCont});

  final HomeController homeScreenCont;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Focus(
        autofocus: true,
        focusNode: homeScreenCont.sliderFocus,
        onFocusChange: (value) {
          homeScreenCont.sliderHasFocus(value);
          if (value) {
            FocusSoundService.play();
          }
          if (homeScreenCont.sliderController.listContent.isNotEmpty) {
            if (homeScreenCont.sliderPageController.value.page != null) {
              homeScreenCont.currentSliderPage(
                  homeScreenCont.sliderController.listContent[
                      homeScreenCont.sliderPageController.value.page!.toInt()]);
            } else {
              homeScreenCont.currentSliderPage(
                  homeScreenCont.sliderController.listContent.first);
            }
          }

          /// Scroll to slider when it gains focus
          if (value && homeScreenCont.sliderKey.currentContext != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Future.delayed(const Duration(milliseconds: 100), () {
                if (homeScreenCont.homeScrollController.hasClients) {
                  Scrollable.ensureVisible(
                    homeScreenCont.sliderKey.currentContext!,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                }
              });
            });
          }
        },
        onKeyEvent: (node, event) => onKeyEvent(node, event),
        child: Column(
          key: homeScreenCont.sliderKey,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: Get.height * 0.62,
                  width: Get.width,
                  child: homeScreenCont.sliderController.listContent.isNotEmpty
                      ? PageView(
                          controller: homeScreenCont.sliderPageController.value,
                          onPageChanged: (value) {
                            homeScreenCont.currentSliderPage(homeScreenCont
                                .sliderController.listContent[value]);
                          },
                          children: List.generate(
                            homeScreenCont.sliderController.listContent.length,
                            (index) {
                              PosterDataModel data = homeScreenCont
                                  .sliderController.listContent[index];

                              return SliderPage(
                                data: data,
                                homeScreenCont: homeScreenCont,
                              );
                            },
                          ),
                        )
                      : CachedImageWidget(
                          url: '', height: Get.height * 0.6, width: Get.width),
                ),
              ],
            ),
            if (homeScreenCont.sliderController.listContent.length.validate() >
                    1 &&
                homeScreenCont.sliderController.isLoading.isFalse)
              DotIndicator(
                pageController: homeScreenCont.sliderPageController.value,
                pages: homeScreenCont.sliderController.listContent,
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
      ),
    );
  }

  KeyEventResult onKeyEvent(FocusNode node, KeyEvent event) {
    try {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          if (homeScreenCont.sliderPageController.value.page != null &&
              homeScreenCont.sliderPageController.value.page! < 1.0) {
            final DashboardController dashCont = Get.find();
            dashCont
                .bottomNavItems[dashCont.selectedBottomNavIndex.value].focusNode
                .requestFocus();
          } else {
            homeScreenCont.sliderPageController.value.previousPage(
                duration: Durations.medium3, curve: Curves.easeIn);
          }
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          homeScreenCont.sliderPageController.value
              .nextPage(duration: Durations.medium3, curve: Curves.easeIn);
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          if (homeScreenCont.firstCategoryFocusNode != null) {
            homeScreenCont.firstCategoryFocusNode!.requestFocus();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        }
        if (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter) {
          final currentSliderPageValue =
              homeScreenCont.sliderController.listContent[
                  homeScreenCont.sliderPageController.value.page!.toInt()];
          handleWatchNowClick(currentSliderPageValue);
          return KeyEventResult.handled;
        }
      }
    } catch (e) {
      log('error in handleKeyEvent: $e');
    }
    return KeyEventResult.ignored;
  }

  void handleWatchNowClick(PosterDataModel data) {
    navigateToContentDetails(data);
  }

  void navigateToContentDetails(PosterDataModel data) {
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
}

class SliderPage extends StatelessWidget {
  const SliderPage(
      {super.key, required this.data, required this.homeScreenCont});

  final HomeController homeScreenCont;
  final PosterDataModel data;

  @override
  Widget build(BuildContext context) {
    final SliderPageController pageController = Get.put(
      SliderPageController(
        currentSliderPageRef: homeScreenCont.currentSliderPage,
        sliderHasFocusRef: homeScreenCont.sliderHasFocus,
        pageData: data,
        pageControllerRef: homeScreenCont.sliderPageController,
        firstCategoryFocusNodeRef: homeScreenCont.firstCategoryFocusNode,
        currentSliderPageValue: homeScreenCont.currentSliderPage,
      ),
      tag: 'home_${data.id}',
      permanent: false,
    );

    return Obx(() => SliderBannerContent(
          data: data,
          showTrailer: pageController.showTrailer.value,
          hasFocus: homeScreenCont.currentSliderPage.value.id == data.id &&
              homeScreenCont.sliderHasFocus.value,
          onTrailerEnded: pageController.onTrailerEnded,
          onPosterTap: pageController.handlePosterTap,
        ));
  }
}
