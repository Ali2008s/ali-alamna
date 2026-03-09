import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/screens/content/content_details_screen.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';
import 'package:streamit_laravel/utils/app_common.dart';
import 'package:streamit_laravel/services/focus_sound_service.dart';

import '../../../components/cached_image_widget.dart';
import '../../../utils/colors.dart';
import '../../../utils/common_base.dart';
import '../../../utils/constants.dart';
import '../../dashboard/dashboard_controller.dart';
import '../../home/home_controller.dart';
import '../../tv_show/tv_show_detail_screen.dart';

class ContinueWatchingItemComponent extends StatelessWidget {
  final PosterDataModel continueWatchData;
  final double? width;
  final VoidCallback? onRemoveTap;
  final ScrollController? control;
  final int index;

  ContinueWatchingItemComponent({
    super.key,
    required this.continueWatchData,
    this.width,
    this.onRemoveTap,
    this.control,
    required this.index,
  });

  final RxBool hasFocus = false.obs;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: continueWatchData.itemFocusNode,
      canRequestFocus: true,
      onFocusChange: (value) {
        hasFocus(value);
        if (value) {
          FocusSoundService.play();
        }
        if (control != null && value) {
          control!.animateTo(
            index * (width ?? Get.width / 4.7),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
      onKeyEvent: (node, event) {
        ///TODO: move focus logic to controller
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowUp && index == 0) {
            final HomeController homeScreenCont = Get.find();
            homeScreenCont.sliderFocus.requestFocus();

            /// Scroll to slider when navigating from Continue Watching
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Future.delayed(const Duration(milliseconds: 150), () {
                if (homeScreenCont.sliderKey.currentContext != null && homeScreenCont.homeScrollController.hasClients) {
                  Scrollable.ensureVisible(homeScreenCont.sliderKey.currentContext!, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                }
              });
            });
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft && index == 0) {
            try {
              final DashboardController controller = Get.find<DashboardController>();
              controller.bottomNavItems[controller.selectedBottomNavIndex.value].focusNode.requestFocus();
            } catch (_) {}
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: InkWell(
        onTap: () {
          doIfLogin(onLoggedIn: () {
            if (continueWatchData.details.entertainmentType == VideoType.tvshow) {
              Get.to(() => TVShowPreviewScreen(), arguments: continueWatchData);
            } else if (continueWatchData.details.entertainmentType == VideoType.movie) {
              Get.to(() => ContentDetailsScreen(isFromContinueWatch: true), arguments: continueWatchData);
            } else if (continueWatchData.details.entertainmentType == VideoType.video) {
              Get.to(() => ContentDetailsScreen(isFromContinueWatch: true), arguments: continueWatchData);
            }
          });
        },
        child: Obx(
          () => Container(
            margin: EdgeInsets.all(hasFocus.value ? 8.0 : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              transform: Matrix4.identity()
                ..translate(
                  0.0,
                  hasFocus.value ? -8.0 : 0.0,
                  0.0,
                )
                ..scale(hasFocus.value ? 1.05 : 1.0),
              width: (width ?? Get.width / 5) * (hasFocus.value ? 1.15 : 1.0),
              decoration: boxDecorationDefault(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: hasFocus.value ? white : transparentColor, width: hasFocus.value ? 3 : 0),
                boxShadow: hasFocus.value
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                          offset: const Offset(0, 10),
                        ),
                      ]
                    : null,
                    color: black,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      CachedImageWidget(
                        url: continueWatchData.posterImage,
                        height: 110,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        topRightRadius: 4,
                        topLeftRadius: 4,
                      ),
                      IgnorePointer(
                        ignoring: true,
                        child: Container(
                          height: 110,
                          width: double.infinity,
                          foregroundDecoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                black.withValues(alpha: 0.0),
                                black.withValues(alpha: 0.4),
                                black.withValues(alpha: 0.6),
                                black.withValues(alpha: 1),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  continueWatchData.details.name,
                                  style: commonSecondaryTextStyle(
                                    color: Colors.white,
                                    size: hasFocus.value ? 16 : 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if(continueWatchData.details.watchedDuration.isNotEmpty)...[
                              const SizedBox(width: 8),
                              Text(
                                continueWatchData.details.watchedDuration,
                                style: commonSecondaryTextStyle(
                                  color: Colors.white,
                                  size: hasFocus.value ? 15 : 14,
                                ),
                              ),
                              ]
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Obx(() {
                      return LinearProgressIndicator(
                        value: calculatePendingPercentage(
                          (continueWatchData.details.duration.isEmpty || continueWatchData.details.duration == "00:00:00") ? "00:00:01" : continueWatchData.details.duration,
                          (continueWatchData.details.watchedDuration.isEmpty || continueWatchData.details.watchedDuration == "00:00:00") ? "00:00:01" : continueWatchData.details.watchedDuration,
                        ).$1,
                        minHeight: hasFocus.value ? 4 : 2,
                        valueColor: const AlwaysStoppedAnimation<Color>(appColorPrimary),
                        backgroundColor: appColorSecondary,
                      );
                    }
                  ),
                  Obx(() {
                    if(hasFocus.value) {
                      return SizedBox(height: 3);
                    }
                      return SizedBox.shrink();
                    }
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
