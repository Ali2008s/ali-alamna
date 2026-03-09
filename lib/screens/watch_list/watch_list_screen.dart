import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/generated/assets.dart';
import 'package:streamit_laravel/screens/content/content_details_screen.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';
import 'package:streamit_laravel/screens/content/components/content_list_shimmer.dart';
import 'package:streamit_laravel/screens/watch_list/components/empty_watch_list_compnent.dart';
import 'package:streamit_laravel/screens/watch_list/components/poster_card.dart';
import 'package:streamit_laravel/screens/watch_list/shimmer_watch_list.dart';
import 'package:streamit_laravel/screens/watch_list/watch_list_controller.dart';
import 'package:streamit_laravel/utils/colors.dart';

import '../../components/app_scaffold.dart';
import '../../components/cached_image_widget.dart';
import '../../main.dart';
import '../../utils/app_common.dart';
import '../../utils/common_base.dart';
import '../../utils/constants.dart';
import '../../utils/empty_error_state_widget.dart';
import '../coming_soon/coming_soon_controller.dart';
import '../coming_soon/coming_soon_detail_screen.dart';
import '../coming_soon/model/coming_soon_response.dart';
import '../tv_show/tv_show_detail_screen.dart';

class WatchListScreen extends StatelessWidget {
  WatchListScreen({super.key});

  final WatchListController watchListCont = Get.find<WatchListController>();

  @override
  Widget build(BuildContext context) {
    return AppScaffoldNew(
      isLoading: watchListCont.currentPage.value == 1 ? false.obs : watchListCont.isLoading,
      currentPage: watchListCont.currentPage,
      scaffoldBackgroundColor: appScreenBackgroundDark,
      topBarBgColor: transparentColor,
      appBartitleText: locale.value.watchlist,
      actions: [
        Obx(
          () => InkWell(
            onTap: () {
              watchListCont.isDelete.value = !watchListCont.isDelete.value;
              watchListCont.selectedPosters.clear();
            },
            splashColor: appColorPrimary.withValues(alpha: 0.4),
            child: const CachedImageWidget(
              url: Assets.iconsIcDelete,
              height: 20,
              width: 20,
              color: appColorPrimary,
            ),
          ).visible(watchListCont.listContent.isNotEmpty),
        ),
        16.width
      ],
      body: Obx(
        () => SnapHelperWidget(
          future: watchListCont.listContentFuture.value,
          initialData: cachedWatchList.isNotEmpty ? cachedWatchList : null,
          loadingWidget: const ShimmerWatchList(),
          errorBuilder: (error) {
            return NoDataWidget(
              titleTextStyle: secondaryTextStyle(color: white),
              subTitleTextStyle: primaryTextStyle(color: white),
              title: error,
              retryText: locale.value.reload,
              imageWidget: const ErrorStateWidget(),
              onRetry: () {
                watchListCont.onSwipeRefresh();
              },
            );
          },
          onSuccess: (res) {
            return Obx(
              () => watchListCont.listContent.isEmpty
                  ? watchListCont.isLoading.isTrue
                      ? const ShimmerMovieList().visible(watchListCont.currentPage.value == 1)
                      : const EmptyWatchListComponent()
                  : LayoutBuilder(builder: (context, constraints) {
                      return AnimatedScrollView(
                        refreshIndicatorColor: appColorPrimary,
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120, top: 16),
                        children: [
                          AnimatedWrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: List.generate(
                              watchListCont.listContent.length,
                              (index) {
                                int reversedIndex = watchListCont.listContent.length - 1 - index;
                                PosterDataModel poster = watchListCont.listContent[reversedIndex];
                                return InkWell(
                                  onTap: () {
                                    doIfLogin(onLoggedIn: () {
                                      if (watchListCont.isDelete.isTrue) {
                                        if (watchListCont.selectedPosters.contains(poster)) {
                                          watchListCont.selectedPosters.remove(poster);
                                        } else {
                                          watchListCont.selectedPosters.add(poster);
                                        }
                                      } else {
                                        if (poster.details.releaseDate.isNotEmpty && isComingSoon(poster.details.releaseDate)) {
                                          ComingSoonController comingSoonCont = Get.put(ComingSoonController());
                                          Get.to(
                                            () => ComingSoonDetailScreen(
                                              comingSoonCont: comingSoonCont,
                                              comingSoonData: ComingSoonModel.fromJson(poster.toPosterJson()),
                                            ),
                                          );
                                        } else {
                                          if (poster.details.type == VideoType.episode || poster.details.type == VideoType.tvshow) {
                                            Get.to(() => TVShowPreviewScreen(), arguments: poster);
                                          } else if (poster.details.type == VideoType.video) {
                                            Get.to(() => ContentDetailsScreen(), arguments: poster);
                                          } else if (poster.details.type == VideoType.movie) {
                                            Get.to(() => ContentDetailsScreen(), arguments: poster);
                                          }
                                        }
                                      }
                                    });
                                  },
                                  child: posterCard(poster: poster, index: index),
                                );
                              },
                            ),
                          ),
                        ],
                        onNextPage: () async {
                          watchListCont.onNextPage();
                        },
                        onSwipeRefresh: () async {
                          watchListCont.onSwipeRefresh();
                        },
                      );
                    }),
            );
          },
        ),
      ),
      widgetsStackedOverBody: [
        Obx(
          () => watchListCont.isDelete.isTrue
              ? Positioned(
                  bottom: 26,
                  left: 16,
                  right: 16,
                  child: AppButton(
                    width: double.infinity,
                    text: locale.value.delete,
                    color: watchListCont.selectedPosters.isNotEmpty ? appColorPrimary : btnColor,
                    enabled: watchListCont.selectedPosters.isNotEmpty,
                    disabledColor: btnColor,
                    textStyle: appButtonTextStyleWhite.copyWith(color: watchListCont.selectedPosters.isNotEmpty ? white : darkGrayTextColor),
                    shapeBorder: RoundedRectangleBorder(borderRadius: radius(6)),
                    onTap: () {
                      watchListCont.handleRemoveFromWatchClick(context);
                    },
                  ),
                )
              : const Offstage(),
        ),
      ],
    );
  }

  Widget posterCard({required PosterDataModel poster, required int index}) {
    return Obx(
      () => Stack(
        children: [
          IgnorePointer(
            ignoring: !watchListCont.isDelete.value,
            child: InkWell(
              onTap: () {
                if (watchListCont.selectedPosters.contains(poster)) {
                  watchListCont.selectedPosters.remove(poster);
                } else {
                  watchListCont.selectedPosters.add(poster);
                }
              },
              child: PosterCard(
                posterDet: poster,
                width: Get.width / 3 - 20,
                height: 160,
              ),
            ),
          ),
          if (watchListCont.isDelete.isTrue)
            Positioned(
              left: 10,
              top: 10,
              child: InkWell(
                onTap: () {
                  if (watchListCont.selectedPosters.contains(poster)) {
                    watchListCont.selectedPosters.remove(poster);
                  } else {
                    watchListCont.selectedPosters.add(poster);
                  }
                },
                child: Container(
                  height: 16,
                  width: 16,
                  decoration: boxDecorationDefault(
                    color: watchListCont.selectedPosters.contains(poster) ? appColorPrimary : white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.check, size: 12, color: white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
