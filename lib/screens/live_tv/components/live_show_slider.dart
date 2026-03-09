import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:streamit_laravel/screens/dashboard/dashboard_controller.dart';
import 'package:streamit_laravel/screens/live_tv/components/live_card.dart';
import 'package:streamit_laravel/screens/live_tv/live_tv_controller.dart';
import 'package:streamit_laravel/screens/live_tv/model/live_tv_dashboard_response.dart';
import 'package:streamit_laravel/utils/app_common.dart';
import 'package:streamit_laravel/utils/colors.dart';
import '../../../components/cached_image_widget.dart';
import 'package:nb_utils/nb_utils.dart' hide DotIndicator;
import '../../../components/dot_indicator.dart';
import '../../../generated/assets.dart';
import '../../../main.dart';
import '../../../utils/common_base.dart';
import '../../../utils/constants.dart';
import '../live_tv_details/live_tv_details_screen.dart';

class LiveShowSliderComponent extends StatelessWidget {
  LiveShowSliderComponent({super.key});

  final LiveTVController liveTvCont = Get.put(LiveTVController());

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Focus(
        focusNode: liveTvCont.sliderFocus,
        onFocusChange: (value) {
          liveTvCont.sliderHasFocus(value);
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
          );
          if (liveTvCont.currentSliderPage.value.id < 0) liveTvCont.currentSliderPage(liveTvCont.liveDashboard.value.data.slider.first);
        },
        onKeyEvent: (node, event) {
          try {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                if (liveTvCont.sliderCont.value.page != null && liveTvCont.sliderCont.value.page! < 1.0) {
                  DashboardController dashCont = Get.find();
                  dashCont.bottomNavItems[dashCont.selectedBottomNavIndex.value].focusNode.requestFocus();
                } else {
                  liveTvCont.sliderCont.value.previousPage(duration: Durations.medium3, curve: Curves.easeIn);
                }

                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                liveTvCont.sliderCont.value.nextPage(duration: Durations.medium3, curve: Curves.easeIn);
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
                doIfLogin(onLoggedIn: () {
                  if (liveTvCont.currentSliderPage.value.access == MovieAccess.paidAccess && liveTvCont.currentSliderPage.value.requiredPlanLevel != 0 && currentSubscription.value.level < liveTvCont.currentSliderPage.value.requiredPlanLevel) {
                    showSubscriptionDialog(title: locale.value.subscriptionRequired,msg: locale.value.pleaseSubscribeOrUpgrade);
                  } else {
                    LiveStream().emit(podPlayerPauseKey);
                    Get.to(() => LiveShowDetailsScreen(), arguments: liveTvCont.currentSliderPage.value);
                  }
                });
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                if(liveTvCont.liveDashboard.value.data.categoryData.isNotEmpty) {
                  final channelData = liveTvCont.liveDashboard.value.data.categoryData.first;
                  if(channelData.channelData.isNotEmpty) {
                    channelData.channelData.first.itemFocusNode.requestFocus();
                  }
                }
                return KeyEventResult.handled;
              }
            }
          } catch (e) {
            log('error in Live SliderHasFocus KeyboardListener: $e');
          }
          return KeyEventResult.ignored;
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                liveTvCont.liveDashboard.value.data.slider.isNotEmpty
                    ? SizedBox(
                        height: Get.height * 0.55,
                        width: Get.width,
                        child: PageView(
                          controller: liveTvCont.sliderCont.value,
                          onPageChanged: (value) {
                            liveTvCont.currentSliderPage(liveTvCont.liveDashboard.value.data.slider[value]);
                          },
                          children: List.generate(
                            liveTvCont.liveDashboard.value.data.slider.length,
                            (index) {
                              ChannelModel data = liveTvCont.liveDashboard.value.data.slider[index];
                              return LiveTvSliderPage(data: data, liveTvCont: liveTvCont);
                            },
                          ),
                        ),
                      )
                    : const CachedImageWidget(url: '', height: 340, width: double.infinity),
                const Positioned(
                  left: 10,
                  top: 10,
                  child: LiveCard(),
                ),
              ],
            ),
            if (liveTvCont.liveDashboard.value.data.slider.length.validate() > 1)
              DotIndicator(
                pageController: liveTvCont.sliderCont.value,
                pages: liveTvCont.liveDashboard.value.data.slider,
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
            32.height
          ],
        ),
      ),
    );
  }
}

class LiveTvSliderPage extends StatelessWidget {
  const LiveTvSliderPage({
    super.key,
    required this.data,
    required this.liveTvCont,
  });

  final ChannelModel data;
  final LiveTVController liveTvCont;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CachedImageWidget(url: data.posterTvImage.validate(), width: double.infinity, height: double.infinity, fit: BoxFit.cover),
        Container(
          height: Get.height * 0.55,
          width: double.infinity,
          foregroundDecoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [black.withValues(alpha: 0.4), black.withValues(alpha: 0.2), black.withValues(alpha: 0.8), black.withValues(alpha: 1)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          right: 0,
          left: 0,
          child: Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 40,
                  padding: EdgeInsets.symmetric(horizontal: 22),
                  decoration: BoxDecoration(
                    borderRadius: radius(4),
                    color: appColorPrimary,
                    border: focusBorder(liveTvCont.sliderHasFocus.value),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const CachedImageWidget(
                        url: Assets.iconsIcPlay,
                        height: 10,
                        width: 10,
                      ),
                      12.width,
                      Text(locale.value.playNow, style: appButtonTextStyleWhite),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}